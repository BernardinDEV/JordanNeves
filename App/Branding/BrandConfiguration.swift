import Foundation

/// White-label brand configuration, decoded from the target's `Brand.json`.
/// To create a new branded app: duplicate the target, swap `Brand.json`,
/// the asset catalog (colors, logos, AppIcon) and the bundled fonts.
struct BrandConfiguration: Decodable {
    struct Contact: Decodable {
        let phone: String
        let whatsapp: String
        let email: String
        let website: String
        let instagram: String
        let linkedin: String
        let address: String
        let city: String
        let businessHours: String
    }

    struct API: Decodable {
        let baseURL: String
    }

    let id: String
    let displayName: String
    let legalName: String
    let tagline: String
    let fontFamily: String
    let contact: Contact
    let api: API

    static let current: BrandConfiguration = {
        guard let url = Bundle.main.url(forResource: "Brand", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let brand = try? JSONDecoder().decode(BrandConfiguration.self, from: data)
        else {
            fatalError("Brand.json missing or invalid — every white-label target must bundle one.")
        }
        return brand
    }()
}
