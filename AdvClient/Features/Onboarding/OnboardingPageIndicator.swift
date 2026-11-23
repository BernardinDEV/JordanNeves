import SwiftUI

struct OnboardingPageIndicator: View {
    let page: Int
    let pageCount: Int

    var body: some View {
        HStack(spacing: 6) {
            ForEach(0..<pageCount, id: \.self) { index in
                Capsule()
                    .fill(index == page ? Theme.primary : Theme.line)
                    .frame(width: index == page ? 20 : 6, height: 6)
            }
        }
        .animation(.snappy(duration: 0.25), value: page)
        .accessibilityElement()
        .accessibilityLabel(Text("onb.page.a11y \(page + 1) \(pageCount)"))
    }
}
