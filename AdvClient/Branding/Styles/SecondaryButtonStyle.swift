import SwiftUI

struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(Theme.font(15, weight: .semibold))
            .frame(maxWidth: .infinity, minHeight: 48)
            .background(Theme.fill.opacity(configuration.isPressed ? 0.7 : 1))
            .foregroundStyle(Theme.primary)
            .clipShape(.rect(cornerRadius: Theme.Radius.control))
            .overlay {
                RoundedRectangle(cornerRadius: Theme.Radius.control).stroke(Theme.line, lineWidth: 1)
            }
    }
}
