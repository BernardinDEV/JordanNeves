import SwiftUI

/// Troca o idioma do app, independente do idioma do aparelho.
struct LanguagePickerRow: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        @Bindable var appState = appState

        HStack(spacing: 13) {
            RowIcon(systemImage: "globe")

            // Fora de um `Form`, o `Picker` em menu mostra só o valor: sem
            // este rótulo a linha era um "English" solto no meio do cartão.
            Text("profile.language")
                .font(Theme.font(15, weight: .medium))
                .foregroundStyle(Theme.primary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .accessibilityHidden(true)

            Picker("profile.language", selection: $appState.language) {
                ForEach(AppLanguage.allCases) { language in
                    Text(language.labelKey).tag(language)
                }
            }
            .pickerStyle(.menu)
            .labelsHidden()
            .tint(Theme.primary)
        }
        .padding(.leading, 15)
        .padding(.trailing, 6)
        .padding(.vertical, 6)
        .frame(minHeight: Theme.minTouchTarget + 12)
    }
}
