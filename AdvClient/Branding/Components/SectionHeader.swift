import SwiftUI

struct SectionHeader<Trailing: View>: View {
    let title: LocalizedStringKey
    @ViewBuilder var trailing: Trailing

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(title)
                .font(Theme.font(13, weight: .semibold))
                .textCase(.uppercase)
                .kerning(0.4)
                .foregroundStyle(Theme.muted)
                .accessibilityAddTraits(.isHeader)
            Spacer(minLength: 8)
            trailing
        }
        .sideMargin()
        .padding(.top, 22)
        .padding(.bottom, 9)
    }
}

extension SectionHeader where Trailing == EmptyView {
    init(_ title: LocalizedStringKey) {
        self.init(title: title) { EmptyView() }
    }
}
