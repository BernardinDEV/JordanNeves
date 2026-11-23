import SwiftUI

struct PositionLegendItem: View {
    let color: Color
    let text: String

    var body: some View {
        HStack(spacing: 6) {
            Circle().fill(color).frame(width: 8, height: 8)
            Text(text)
                .font(Theme.font(12.5))
                .foregroundStyle(Theme.muted)
        }
    }
}
