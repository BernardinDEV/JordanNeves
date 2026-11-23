import SwiftUI

/// Item de checklist: caixa à esquerda, texto à direita, a linha inteira
/// tocável e com 44 pt de altura. Por ser um `Toggle`, o VoiceOver anuncia
/// "marcado / desmarcado" sem trabalho extra.
struct ChecklistToggleStyle: ToggleStyle {
    func makeBody(configuration: Configuration) -> some View {
        Button {
            configuration.isOn.toggle()
        } label: {
            HStack(alignment: .firstTextBaseline, spacing: 10) {
                Image(systemName: configuration.isOn ? "checkmark.square.fill" : "square")
                    .font(.title3)
                    .foregroundStyle(configuration.isOn ? Theme.primary : Theme.muted)
                configuration.label
                    .font(Theme.font(14))
                    .foregroundStyle(Theme.body)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(minHeight: Theme.minTouchTarget)
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
    }
}
