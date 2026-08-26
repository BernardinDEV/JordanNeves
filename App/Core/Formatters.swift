import Foundation

// MARK: - CNJ case number

/// A Brazilian unified case number: `NNNNNNN-DD.AAAA.J.TR.OOOO`.
///
/// The two check digits are an ISO 7064 MOD 97-10 checksum over the other
/// eighteen. Validating them catches a mistyped number in the firm's panel
/// before it reaches a client who would otherwise compare it against an e-mail
/// from their accountant and find it wrong.
struct CNJNumber: Equatable, Hashable, Sendable {
    /// Sequential number within the origin unit (7 digits).
    let sequential: String
    /// Check digits (2).
    let checkDigits: String
    /// Filing year (4).
    let year: String
    /// Judiciary segment (1) — 5 is labour, 8 is state court.
    let segment: String
    /// Court within the segment (2).
    let court: String
    /// Originating unit (4).
    let origin: String

    /// Parses digits or a formatted string. Returns `nil` unless there are
    /// exactly 20 digits — it does not check the digits, so callers can render a
    /// number that arrived malformed while `isValid` reports the problem.
    init?(_ raw: String) {
        let digits = raw.filter(\.isNumber)
        guard digits.count == 20 else { return nil }
        func slice(_ start: Int, _ length: Int) -> String {
            let from = digits.index(digits.startIndex, offsetBy: start)
            let to = digits.index(from, offsetBy: length)
            return String(digits[from..<to])
        }
        sequential = slice(0, 7)
        checkDigits = slice(7, 2)
        year = slice(9, 4)
        segment = slice(13, 1)
        court = slice(14, 2)
        origin = slice(16, 4)
    }

    /// `0012345-16.2025.5.17.0004`
    var formatted: String {
        "\(sequential)-\(checkDigits).\(year).\(segment).\(court).\(origin)"
    }

    var digits: String {
        sequential + checkDigits + year + segment + court + origin
    }

    /// The check digits this number *should* carry.
    var expectedCheckDigits: String {
        let base = sequential + year + segment + court + origin + "00"
        // Modulo built up digit by digit: the full value is 20 digits and would
        // overflow a UInt64.
        var remainder = 0
        for character in base {
            guard let digit = character.wholeNumberValue else { continue }
            remainder = (remainder * 10 + digit) % 97
        }
        return String(format: "%02d", 98 - remainder)
    }

    var isValid: Bool { checkDigits == expectedCheckDigits }

    /// Segment plus court, the way courts are named in conversation: `TRT-17`.
    var courtLabel: String {
        let number = Int(court) ?? 0
        switch segment {
        case "4": return "TRF-\(number)"
        case "5": return "TRT-\(number)"
        case "8": return "TJ (\(court))"
        default: return "\(segment).\(court)"
        }
    }
}

// MARK: - Formatting

enum Format {

    static let brazil = Locale(identifier: "pt_BR")

    /// Locale for user-facing text produced outside SwiftUI's environment.
    ///
    /// `String(localized:)` resolves against the process locale, which follows
    /// the *device* language — so without this a client who switched the app to
    /// English would still read "em 54 dias" under an English deadline. `AppState`
    /// keeps it in step with the in-app language switch.
    static var uiLocale: Locale = brazil

    private static var bundleCache: [String: Bundle] = [:]

    /// The `.lproj` bundle for a locale.
    ///
    /// Passing `locale:` to `String(localized:)` only formats the interpolated
    /// values — it does not choose the translation table. Selecting the language
    /// means handing it the matching bundle, which the String Catalog compiles
    /// into `pt-BR.lproj` and `en.lproj` at build time.
    static func bundle(for locale: Locale) -> Bundle {
        let key = locale.identifier
        if let cached = bundleCache[key] { return cached }

        var candidates = [key, key.replacingOccurrences(of: "_", with: "-")]
        if let language = locale.language.languageCode?.identifier { candidates.append(language) }

        for candidate in candidates {
            if let path = Bundle.main.path(forResource: candidate, ofType: "lproj"),
               let bundle = Bundle(path: path) {
                bundleCache[key] = bundle
                return bundle
            }
        }
        return .main
    }

    /// Localised string resolved against an explicit locale.
    static func string(_ key: String.LocalizationValue, locale: Locale = Format.uiLocale) -> String {
        String(localized: key, bundle: bundle(for: locale), locale: locale)
    }

    private static let currency: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = brazil
        return formatter
    }()

    /// `R$ 84.200,00`
    static func money(_ value: Decimal) -> String {
        currency.string(from: value as NSDecimalNumber) ?? "—"
    }

    /// `14/09/2026`
    static func date(_ date: Date, locale: Locale = brazil) -> String {
        date.formatted(.dateTime.day(.twoDigits).month(.twoDigits).year().locale(locale))
    }

    /// `Sexta, 27/07`
    static func weekdayDate(_ date: Date, locale: Locale = brazil) -> String {
        let weekday = date.formatted(.dateTime.weekday(.wide).locale(locale))
        return "\(weekday.prefix(1).uppercased())\(weekday.dropFirst()), " +
            date.formatted(.dateTime.day(.twoDigits).month(.twoDigits).locale(locale))
    }

    /// `27/07/2026 · 14h30`
    static func dateTime(_ date: Date, locale: Locale = brazil) -> String {
        let time = date.formatted(.dateTime.hour(.twoDigits(amPM: .omitted)).minute().locale(locale))
        return "\(self.date(date, locale: locale)) · \(time.replacingOccurrences(of: ":", with: "h"))"
    }

    /// How far away a deadline is, in words: `em 54 dias`, `amanhã`, `hoje`,
    /// `vencido há 3 dias`. Pairing this with the absolute date is the app's rule
    /// for every deadline — the date alone forces mental arithmetic, the countdown
    /// alone loses the reference.
    static func countdown(
        to deadline: Date,
        now: Date = .now,
        calendar: Calendar = Rules.calendar,
        locale: Locale = Format.uiLocale
    ) -> String {
        let remaining = Rules.days(from: now, to: deadline, calendar: calendar)
        switch remaining {
        case 0: return string("deadline.today", locale: locale)
        case 1: return string("deadline.tomorrow", locale: locale)
        case 2...: return string("deadline.inDays \(remaining)", locale: locale)
        case -1: return string("deadline.overdueYesterday", locale: locale)
        default: return string("deadline.overdueDays \(abs(remaining))", locale: locale)
        }
    }

    /// `14/09/2026 · em 54 dias`
    static func deadline(
        _ deadline: Date,
        now: Date = .now,
        calendar: Calendar = Rules.calendar,
        locale: Locale = Format.uiLocale
    ) -> String {
        "\(date(deadline, locale: locale)) · \(countdown(to: deadline, now: now, calendar: calendar, locale: locale))"
    }

    /// `14.902.336/0001-08`
    static func cnpj(_ raw: String) -> String {
        let d = raw.filter(\.isNumber)
        guard d.count == 14 else { return raw }
        func part(_ start: Int, _ length: Int) -> String {
            let from = d.index(d.startIndex, offsetBy: start)
            return String(d[from..<d.index(from, offsetBy: length)])
        }
        return "\(part(0, 2)).\(part(2, 3)).\(part(5, 3))/\(part(8, 4))-\(part(12, 2))"
    }
}
