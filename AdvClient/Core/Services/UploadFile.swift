import Foundation
import UniformTypeIdentifiers

/// Um arquivo que o cliente escolheu para enviar ao escritório.
///
/// Carrega o conteúdo, não só o nome: o protocolo antigo recebia apenas
/// `fileName`, o que bastava para a demonstração e não servia para enviar nada.
struct UploadFile: Sendable, Equatable {
    let name: String
    let data: Data
    let contentType: String

    /// Lê um arquivo vindo do `fileImporter`. A URL é de escopo de segurança:
    /// fora do par `start/stopAccessing` a leitura falha em aparelho, mesmo
    /// funcionando no simulador.
    init(contentsOf url: URL) throws {
        let granted = url.startAccessingSecurityScopedResource()
        defer { if granted { url.stopAccessingSecurityScopedResource() } }
        data = try Data(contentsOf: url)
        name = url.lastPathComponent
        contentType = UTType(filenameExtension: url.pathExtension)?.preferredMIMEType
            ?? "application/octet-stream"
    }

    init(name: String, data: Data, contentType: String) {
        self.name = name
        self.data = data
        self.contentType = contentType
    }

    /// Limite do envio pelo app. Arquivo maior que isto é escaneamento de
    /// processo inteiro, e vai por outro canal.
    static let maxBytes = 25 * 1024 * 1024
}
