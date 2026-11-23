import SwiftUI

struct ContractsArtRow: View {
    let label: LocalizedStringKey
    let value: String
    let tone: Color

    var body: some View {
        HStack {
            Text(label)
                .font(Theme.font(13.5))
                .foregroundStyle(Theme.muted)
            Spacer()
            Text(value)
                .font(Theme.mono(16, weight: .semibold))
                .foregroundStyle(tone)
        }
        .padding(.vertical, 9)
        .overlay(alignment: .bottom) {
            Rectangle().fill(Theme.line).frame(height: 1)
        }
    }
}
