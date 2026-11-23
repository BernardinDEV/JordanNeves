import SwiftUI

/// O texto do tribunal, recolhido e deliberadamente secundário: acessível para
/// quem quer conferir, nunca a primeira coisa que o cliente lê.
struct OfficialTextDisclosure: View {
    let text: String
    let courtShort: String

    @State private var isExpanded = false

    var body: some View {
        DisclosureGroup(isExpanded: $isExpanded) {
            Text(text)
                .font(Theme.mono(12))
                .foregroundStyle(Theme.muted)
                .lineSpacing(4)
                .textSelection(.enabled)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.top, 10)
        } label: {
            Text("movement.officialText.toggle \(courtShort)")
                .font(Theme.font(13.5))
                .foregroundStyle(Theme.primary)
                .frame(minHeight: Theme.minTouchTarget - 26)
        }
        .tint(Theme.primary)
        .padding(13)
        .background(Theme.fill, in: .rect(cornerRadius: Theme.Radius.control))
    }
}
