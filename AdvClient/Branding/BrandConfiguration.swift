import Foundation

/// Texto que muda por escritório **e** por idioma.
///
/// Aceita as duas formas no `Brand.json`:
///
/// ```json
/// "tagline": "Mesmo texto nos dois idiomas"
/// "tagline": { "pt-BR": "Jurídico empresarial", "en": "Corporate law" }
/// ```
///
/// Existe porque texto de marca não pode morar no catálogo de strings do
/// núcleo: horário de atendimento e posicionamento são de um escritório só, e
/// deixá-los lá obriga a editar o núcleo a cada marca nova.
struct BrandText: Decodable {
    private let byLanguage: [String: String]

    /// Chave usada quando o JSON traz uma string simples, sem idioma.
    private static let anyLanguage = "*"
    private static let fallbackLanguage = "en"

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let single = try? container.decode(String.self) {
            byLanguage = [Self.anyLanguage: single]
        } else {
            byLanguage = try container.decode([String: String].self)
        }
    }

    /// Resolve contra o idioma escolhido **no app** (`Format.uiLocale`), não o
    /// do aparelho — é a mesma regra que o resto dos textos gerados fora do
    /// SwiftUI segue.
    ///
    /// A ordem cobre a normalização do Foundation: `Locale(identifier: "pt-BR")`
    /// devolve `pt_BR` em `identifier`, então o hífen é tentado também. Nunca
    /// devolve vazio por falta de tradução — cair para outro idioma é melhor do
    /// que um rótulo em branco na tela do cliente.
    func resolved(for locale: Locale = Format.uiLocale) -> String {
        let identifier = locale.identifier
        let candidates = [
            identifier,
            identifier.replacingOccurrences(of: "_", with: "-"),
            locale.language.languageCode?.identifier ?? identifier,
            Self.anyLanguage,
            Self.fallbackLanguage,
        ]
        for key in candidates {
            if let value = byLanguage[key] { return value }
        }
        return byLanguage.values.first ?? ""
    }
}

/// Configuração da marca, lida do `Brand.json` que o target empacota.
///
/// Um escritório novo é uma pasta em `Brands/`, não uma alteração aqui. Se você
/// precisou escrever o nome de um escritório em qualquer arquivo de
/// `AdvClient/`, isso é um vazamento — o valor pertence a esta struct.
///
/// As cores ficam no catálogo de assets da marca (`BrandPrimary`, `BrandBrass`,
/// `BrandCard`, `BrandOnBrand`, …) e não aqui: assim o Xcode resolve claro e
/// escuro sozinho e o SwiftUI não precisa reconstruir a view ao trocar de tema.
struct BrandConfiguration: Decodable {
    struct Contact: Decodable {
        let phone: String
        let whatsapp: String
        let email: String
        let website: String
        let instagram: String?
        let linkedin: String?
        let address: String
        let city: String
        let businessHours: BrandText
    }

    struct API: Decodable {
        let baseURL: String
    }

    struct Store: Decodable {
        /// Usado para o link de avaliação e para a checagem de versão mínima.
        /// Nulo enquanto o app da marca não foi publicado.
        let appStoreID: String?
    }

    let id: String
    let displayName: String
    let legalName: String
    let fontFamily: String
    let tagline: BrandText
    let contact: Contact
    let api: API
    let store: Store?

    static let current: BrandConfiguration = {
        guard let url = Bundle.main.url(forResource: "Brand", withExtension: "json") else {
            fatalError(
                """
                Brand.json não está no bundle.
                Todo target de marca precisa incluir Brands/<Marca>/Resources — \
                confira o grupo sincronizado do target no Xcode.
                """
            )
        }
        do {
            return try JSONDecoder().decode(BrandConfiguration.self, from: Data(contentsOf: url))
        } catch {
            // Falhar no lançamento é intencional: um Brand.json quebrado gera um
            // app com o nome de outro escritório, e isso não pode chegar à loja.
            fatalError("Brand.json inválido (\(url.path)): \(error)")
        }
    }()
}
