import SwiftUI

/// The one green thing in the app. It is deliberately not the primary style:
/// leaving for WhatsApp is an exit, never the main action on a screen.
struct WhatsAppButtonStyle: ButtonStyle {
    static let green = Color(red: 27 / 255, green: 140 / 255, blue: 90 / 255)

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(Theme.font(15, weight: .semibold))
            .frame(maxWidth: .infinity, minHeight: 48)
            .background(Self.green.opacity(configuration.isPressed ? 0.12 : 0.07))
            .foregroundStyle(Self.green)
            .clipShape(.rect(cornerRadius: Theme.Radius.control))
            .overlay {
                RoundedRectangle(cornerRadius: Theme.Radius.control)
                    .stroke(Self.green.opacity(0.4), lineWidth: 1)
            }
    }
}
