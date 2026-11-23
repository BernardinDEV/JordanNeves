import SwiftUI

enum AppLanguage: String, CaseIterable, Identifiable {
    case portuguese = "pt-BR"
    case english = "en"

    var id: String { rawValue }

    var labelKey: LocalizedStringKey {
        switch self {
        case .portuguese: "language.portuguese"
        case .english: "language.english"
        }
    }

    var locale: Locale { Locale(identifier: rawValue) }
}
