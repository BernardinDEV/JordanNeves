import Foundation

/// Builds the outbound WhatsApp link that replaced the in-app conversation.
///
/// The link itself is trivial; the value is in the pre-filled message. Sending
/// the company name and the case number along keeps the firm's "one subject, one
/// case" rule alive without the app owning a message thread — which is the whole
/// point of the trade: no inbox, no realtime, no SLA the firm can't measure.
enum WhatsAppLink {

    /// What the client was looking at when they reached for the button.
    enum Context: Equatable, Sendable {
        case general
        case movement(caseNumber: String, caseTitle: String, movementDate: Date)
        case contract(title: String)
        case hearingConflict(caseNumber: String, hearingDate: Date)
        case missingInvite

        /// Body of the message, with the context already filled in. The client
        /// only has to type the question itself.
        func message(companyName: String, locale: Locale = Format.brazil) -> String {
            let hello = Format.string("wa.greeting \(companyName)", locale: locale)
            switch self {
            case .general:
                return hello
            case let .movement(number, title, date):
                let about = Format.string("wa.aboutMovement \(Format.date(date, locale: locale)) \(title) \(number)", locale: locale)
                return "\(hello)\n\n\(about)\n\n\(Format.string("wa.myQuestion", locale: locale))"
            case let .contract(title):
                let about = Format.string("wa.aboutContract \(title)", locale: locale)
                return "\(hello)\n\n\(about)\n\n\(Format.string("wa.myQuestion", locale: locale))"
            case let .hearingConflict(number, date):
                let about = Format.string("wa.aboutHearing \(Format.dateTime(date, locale: locale)) \(number)", locale: locale)
                return "\(hello)\n\n\(about)"
            case .missingInvite:
                return Format.string("wa.missingInvite", locale: locale)
            }
        }
    }

    /// Strips a phone number down to the digits `wa.me` expects, and adds Brazil's
    /// country code when the number was written the local way.
    static func normalize(phone: String) -> String? {
        var digits = phone.filter(\.isNumber)
        guard !digits.isEmpty else { return nil }
        if digits.hasPrefix("0") { digits.removeFirst() }
        // 10 or 11 digits means area code + subscriber, i.e. a Brazilian number
        // typed without the country code.
        if digits.count == 10 || digits.count == 11 { digits = "55" + digits }
        guard digits.count >= 12, digits.count <= 15 else { return nil }
        return digits
    }

    /// `https://wa.me/5527344282500?text=...`
    ///
    /// `wa.me` opens the installed app when there is one and falls back to the web
    /// client otherwise, so the app needs no `LSApplicationQueriesSchemes` entry
    /// and no branching on whether WhatsApp is installed.
    static func url(phone: String, message: String) -> URL? {
        guard let number = normalize(phone: phone) else { return nil }
        var components = URLComponents()
        components.scheme = "https"
        components.host = "wa.me"
        components.path = "/\(number)"
        components.queryItems = [URLQueryItem(name: "text", value: message)]
        return components.url
    }

    /// Convenience over `url(phone:message:)` for a given context.
    static func url(phone: String, context: Context, companyName: String) -> URL? {
        url(phone: phone, message: context.message(companyName: companyName))
    }
}
