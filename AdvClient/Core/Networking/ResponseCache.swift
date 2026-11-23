import Foundation
import CryptoKit

// MARK: - O que fica guardado

/// Uma resposta guardada, com as duas datas que decidem o que fazer com ela.
///
/// Guarda o **corpo bruto**, não o objeto decodificado: assim uma entrada serve
/// a qualquer `Response`, e uma mudança no modelo não invalida silenciosamente
/// um cache que continua no disco.
struct CachedPayload: Codable, Sendable, Equatable {
    let data: Data
    /// Quando a resposta chegou do servidor. É esta data que a tela mostra ao
    /// cliente quando o dado vem do cache — o app não finge que é de agora.
    let storedAt: Date
    /// Até aqui responde sem tocar na rede.
    let expiresAt: Date
    /// Depois de `expiresAt` e até aqui, só vale como resposta de emergência
    /// quando a rede falha.
    let staleUntil: Date

    func isFresh(now: Date = .now) -> Bool { now < expiresAt }
    func isServableWhenStale(now: Date = .now) -> Bool { now < staleUntil }

    func age(now: Date = .now) -> TimeInterval { now.timeIntervalSince(storedAt) }
}

// MARK: - Cache

/// Cache de respostas em dois níveis: memória para a sessão, disco criptografado
/// para sobreviver ao relançamento.
///
/// ## Por que não o `URLCache`
///
/// O cache do sistema grava o corpo das respostas em claro dentro de
/// `Library/Caches`, sem proteção de arquivo, e essa pasta entra em backup de
/// aparelho e em extração forense trivial. Para um app que carrega processo,
/// contrato e honorário de uma empresa, isso é o vazamento mais barato que
/// existe. A sessão de rede desliga o `URLCache` e este objeto ocupa o lugar,
/// com três diferenças que importam:
///
/// - **Proteção de arquivo completa.** O arquivo é ilegível enquanto o aparelho
///   está bloqueado, mesmo com o disco montado.
/// - **Fora do backup.** `isExcludedFromBackup` no diretório: nada de processo
///   do cliente aparecendo num backup do iCloud de outro aparelho.
/// - **Escopo por conta.** A chave inclui quem estava logado. Trocar de conta no
///   mesmo aparelho não faz uma responder pelo cache da outra.
///
/// ## Ainda assim, `purgeAll()` no logout
///
/// Chave com escopo evita colisão, não apagamento. Sair da conta tem que apagar:
/// é o `AppState.signOut()` que chama.
actor ResponseCache {

    static let shared = ResponseCache()

    private let directory: URL?
    private let memoryLimit: Int
    private let diskBudget: Int

    private var memory: [String: CachedPayload] = [:]
    private var writesSinceLastPrune = 0
    private let pruneEvery = 20

    init(
        directory: URL? = ResponseCache.defaultDirectory(),
        memoryLimit: Int = 64,
        diskBudget: Int = 20 * 1024 * 1024
    ) {
        self.directory = directory
        self.memoryLimit = memoryLimit
        self.diskBudget = diskBudget
    }

    // MARK: Chave

    /// Chave de uma chamada, com escopo de conta.
    ///
    /// O escopo entra **dentro** do que é resumido, não como prefixo legível:
    /// o nome do arquivo no disco não pode dizer de quem é o dado guardado.
    /// O prefixo de versão permite invalidar tudo de uma vez quando o formato
    /// mudar — basta trocar `v1`.
    nonisolated static func key(scope: String, canonical: String) -> String {
        let input = "v1|\(scope)|\(canonical)"
        let digest = SHA256.hash(data: Data(input.utf8))
        return digest.map { String(format: "%02x", $0) }.joined()
    }

    // MARK: Leitura

    /// Devolve a entrada guardada, **vencida ou não**. Quem chama decide: fresca
    /// responde direto, vencida só vale se a rede falhou.
    func read(_ key: String) -> CachedPayload? {
        if let hit = memory[key] { return hit }
        guard let stored = readFromDisk(key) else { return nil }
        memory[key] = stored
        enforceMemoryLimit()
        return stored
    }

    // MARK: Escrita

    func store(_ data: Data, for key: String, policy: CachePolicy, now: Date = .now) {
        guard policy.isEnabled else { return }
        let payload = CachedPayload(
            data: data,
            storedAt: now,
            expiresAt: now.addingTimeInterval(policy.ttl),
            staleUntil: now.addingTimeInterval(policy.ttl + policy.staleWindow)
        )
        write(payload, for: key, toDisk: policy.writesToDisk)
    }

    func write(_ payload: CachedPayload, for key: String, toDisk: Bool) {
        memory[key] = payload
        enforceMemoryLimit()
        guard toDisk else { return }
        writeToDisk(payload, key: key)
        writesSinceLastPrune += 1
        if writesSinceLastPrune >= pruneEvery {
            writesSinceLastPrune = 0
            purgeExpired()
        }
    }

    // MARK: Remoção

    func remove(_ key: String) {
        memory[key] = nil
        guard let directory else { return }
        try? FileManager.default.removeItem(at: fileURL(for: key, in: directory))
    }

    /// Apaga tudo. Chamada obrigatória no logout e quando o ambiente é
    /// considerado comprometido.
    func purgeAll() {
        memory.removeAll()
        guard let directory else { return }
        let manager = FileManager.default
        guard let files = try? manager.contentsOfDirectory(at: directory, includingPropertiesForKeys: nil) else { return }
        for file in files {
            try? manager.removeItem(at: file)
        }
    }

    /// Remove o que passou até da janela de emergência e, se ainda estiver acima
    /// do orçamento de disco, os mais antigos até caber.
    func purgeExpired(now: Date = .now) {
        memory = memory.filter { $0.value.isServableWhenStale(now: now) }

        guard let directory else { return }
        let manager = FileManager.default
        guard let files = try? manager.contentsOfDirectory(at: directory, includingPropertiesForKeys: nil) else { return }

        var surviving: [(url: URL, size: Int, storedAt: Date)] = []
        for file in files {
            // Arquivo ilegível aqui costuma ser aparelho bloqueado, não arquivo
            // corrompido — apagar seria jogar fora cache válido por causa da
            // proteção que a gente mesmo pediu.
            guard let raw = try? Data(contentsOf: file) else { continue }
            guard let payload = try? Self.plistDecoder.decode(CachedPayload.self, from: raw) else {
                try? manager.removeItem(at: file)
                continue
            }
            guard payload.isServableWhenStale(now: now) else {
                try? manager.removeItem(at: file)
                continue
            }
            surviving.append((file, raw.count, payload.storedAt))
        }

        var total = surviving.reduce(0) { $0 + $1.size }
        guard total > diskBudget else { return }
        for entry in surviving.sorted(by: { $0.storedAt < $1.storedAt }) {
            try? manager.removeItem(at: entry.url)
            // O nome do arquivo é a própria chave: some também da memória, senão
            // a entrada continuaria viva até o app fechar.
            memory[entry.url.deletingPathExtension().lastPathComponent] = nil
            total -= entry.size
            if total <= diskBudget { break }
        }
    }

    // MARK: Disco

    private func fileURL(for key: String, in directory: URL) -> URL {
        directory.appendingPathComponent("\(key).cache", isDirectory: false)
    }

    private func writeToDisk(_ payload: CachedPayload, key: String) {
        guard let directory else { return }
        do {
            let encoded = try Self.plistEncoder.encode(payload)
            try encoded.write(
                to: fileURL(for: key, in: directory),
                // `.completeFileProtection`: ilegível com o aparelho bloqueado.
                // `.atomic`: uma escrita interrompida não deixa meio arquivo,
                // que na leitura seguinte viraria uma resposta truncada.
                options: [.atomic, .completeFileProtection]
            )
        } catch {
            // Escrever cache é otimização. Aparelho bloqueado ou disco cheio
            // não podem virar erro na tela do cliente — a memória continua
            // servindo esta sessão.
            NetworkLog.warning("cache: falha ao gravar em disco")
        }
    }

    private func readFromDisk(_ key: String) -> CachedPayload? {
        guard let directory else { return nil }
        guard let raw = try? Data(contentsOf: fileURL(for: key, in: directory)) else { return nil }
        return try? Self.plistDecoder.decode(CachedPayload.self, from: raw)
    }

    private func enforceMemoryLimit() {
        guard memory.count > memoryLimit else { return }
        let excess = memory.count - memoryLimit
        let oldest = memory
            .sorted { $0.value.storedAt < $1.value.storedAt }
            .prefix(excess)
            .map { $0.key }
        for key in oldest {
            memory[key] = nil
        }
    }

    // MARK: Configuração do diretório

    /// Property list binária, e não JSON: o corpo guardado é `Data`, e em JSON
    /// isso vira base64 — um terço a mais de disco para nada.
    private static let plistEncoder: PropertyListEncoder = {
        let encoder = PropertyListEncoder()
        encoder.outputFormat = .binary
        return encoder
    }()

    private static let plistDecoder = PropertyListDecoder()

    /// `Application Support/NetworkCache`, protegido e fora do backup.
    ///
    /// Não é `Caches/`: o sistema apaga `Caches/` sob pressão de disco a qualquer
    /// momento, e a janela de emergência offline depende de o arquivo continuar
    /// lá quando o cliente abrir o app no elevador do fórum.
    nonisolated static func defaultDirectory() -> URL? {
        let manager = FileManager.default
        guard let base = try? manager.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        ) else { return nil }

        var directory = base.appendingPathComponent("NetworkCache", isDirectory: true)
        if !manager.fileExists(atPath: directory.path) {
            try? manager.createDirectory(
                at: directory,
                withIntermediateDirectories: true,
                attributes: [.protectionKey: FileProtectionType.complete]
            )
        }

        var values = URLResourceValues()
        values.isExcludedFromBackup = true
        try? directory.setResourceValues(values)

        return directory
    }
}
