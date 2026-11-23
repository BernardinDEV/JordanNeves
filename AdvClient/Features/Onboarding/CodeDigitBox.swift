import SwiftUI

/// Uma das seis caixas do código.
struct CodeDigitBox: View {
    let digit: Character?
    let isCursor: Bool

    var body: some View {
        Text(digit.map(String.init) ?? " ")
            .font(Theme.mono(24, weight: .medium))
            .foregroundStyle(Theme.primary)
            .frame(maxWidth: .infinity, minHeight: 58)
            .background(Theme.card, in: .rect(cornerRadius: Theme.Radius.control))
            .overlay {
                RoundedRectangle(cornerRadius: Theme.Radius.control)
                    .stroke(isCursor ? Theme.primary : Theme.line, lineWidth: isCursor ? 2 : 1)
            }
    }
}
