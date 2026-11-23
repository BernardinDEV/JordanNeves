/// O que o escritório oferece no app.
///
/// Nem todo provedor jurídico guarda documentos, e nem todo escritório quer
/// receber arquivo pelo app. Quem decide é o backend, a partir do provedor e do
/// contrato do escritório — e manda junto com o snapshot, para valer também
/// sem rede. As telas escondem o que não existe em vez de mostrar um botão que
/// falha.
struct ProviderCapabilities: Codable, Equatable, Sendable {
    /// Aba Documentos, contratos no painel e o atalho "Ver todos".
    var documents: Bool
    /// Envio de arquivo pelo app. Só vale com `documents`.
    var uploads: Bool

    /// Tudo ligado — o que os dados de demonstração oferecem.
    static let all = ProviderCapabilities(documents: true, uploads: true)

    var canUpload: Bool { documents && uploads }
}
