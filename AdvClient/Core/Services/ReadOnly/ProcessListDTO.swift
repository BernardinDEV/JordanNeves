import Foundation

/// A resposta de `GET /app/v1/processos` da fonte somente leitura.
///
/// Datas chegam como texto (`"2026-10-03"`) e são lidas aqui, uma a uma: uma
/// data malformada descarta o andamento, não a lista.
struct ProcessListDTO: Decodable, Sendable {
    let updatedAt: String?
    let total: Int?
    let processes: LossyList<Process>

    private enum CodingKeys: String, CodingKey {
        case updatedAt = "atualizado_em"
        case total
        case processes = "processos"
    }

    struct Process: Decodable, Sendable {
        let number: String
        let court: String?
        let body: String?
        let caseClass: String?
        let role: String?
        let lastMovement: Movement?

        private enum CodingKeys: String, CodingKey {
            case number = "numero_cnj"
            case court = "tribunal"
            case body = "orgao"
            case caseClass = "classe"
            case role = "polo"
            case lastMovement = "ultimo_andamento"
        }
    }

    struct Movement: Decodable, Sendable {
        let date: String?
        let text: String?
        let source: String?

        private enum CodingKeys: String, CodingKey {
            case date = "data"
            case text = "texto"
            case source = "fonte"
        }
    }
}

// MARK: - Para o domínio

extension ProcessListDTO {

    /// Sem documentos nem envio: a fonte só lê processos. `atualizado_em` nulo
    /// vira `.distantPast`, que esconde o "Atualizado em …" em vez de inventar
    /// uma data.
    func domain() -> ClientSnapshot {
        ClientSnapshot(
            cases: processes.elements.compactMap { $0.domain() },
            documents: [],
            pendencies: [],
            invoices: [],
            lastSyncedAt: updatedAt.flatMap(ISO8601Parsing.date(from:)) ?? .distantPast,
            capabilities: ProviderCapabilities(documents: false, uploads: false)
        )
    }
}

extension ProcessListDTO.Process {

    func domain() -> LegalCase? {
        let digits = number.filter(\.isNumber)
        guard digits.count == 20, let id = Self.stableID(cnjDigits: digits) else { return nil }

        let body = body?.nonEmpty
        let activity = lastMovement.flatMap { movement -> CourtActivity? in
            guard let date = movement.date.flatMap(ISO8601Parsing.date(from:)) else { return nil }
            return CourtActivity(date: date, source: movement.source?.nonEmpty)
        }

        return LegalCase(
            id: id,
            number: number,
            title: body ?? caseClass?.nonEmpty ?? number,
            area: Self.area(caseClass: caseClass, cnjDigits: digits),
            court: body ?? court ?? "",
            courtShort: court?.nonEmpty ?? "",
            isUnderSeal: false,
            opposingParty: nil,
            claimValue: nil,
            // Sem provisão a linha de risco não aparece; o nível fica no
            // menor valor só para preencher o tipo.
            risk: .low,
            provision: nil,
            responsibleLawyer: "",
            openedAt: activity?.date ?? .distantPast,
            closedAt: nil,
            // O texto do tribunal fica de fora: sem explicação do escritório
            // ele não pode chegar ao cliente, e guardá-lo aqui só criaria o
            // risco de alguém mostrá-lo.
            movements: [],
            hearing: nil,
            caseClass: caseClass?.nonEmpty,
            clientRole: role?.nonEmpty,
            lastCourtActivity: activity
        )
    }

    /// O mesmo processo tem sempre o mesmo id, entre atualizações e
    /// relançamentos — é o que mantém a navegação e o "lido" estáveis.
    static func stableID(cnjDigits: String) -> UUID? {
        let hex = String(repeating: "0", count: 12) + cnjDigits
        let parts = [
            hex.prefix(8),
            hex.dropFirst(8).prefix(4),
            hex.dropFirst(12).prefix(4),
            hex.dropFirst(16).prefix(4),
            hex.dropFirst(20),
        ].map(String.init)
        return UUID(uuidString: parts.joined(separator: "-"))
    }

    /// Pela classe, quando ela diz; senão pelo segmento da Justiça no número
    /// CNJ (o `J` de `NNNNNNN-DD.AAAA.J.TR.OOOO`).
    static func area(caseClass: String?, cnjDigits: String) -> PracticeArea {
        let text = (caseClass ?? "").folding(options: [.caseInsensitive, .diacriticInsensitive], locale: nil)
        if text.contains("trabalh") || text.contains("reclamacao trabalhista") { return .labor }
        if text.contains("fiscal") || text.contains("tribut") { return .tax }
        if ["alimentos", "divorcio", "inventario", "guarda", "familia", "uniao estavel"].contains(where: text.contains) {
            return .family
        }
        if text.contains("civel") || text.contains("civil") || text.contains("consumidor") { return .civil }

        let segment = cnjDigits.dropFirst(13).first
        return segment == "5" ? .labor : .other
    }
}

private extension String {
    var nonEmpty: String? {
        let trimmed = trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}
