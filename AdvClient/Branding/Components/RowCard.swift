import SwiftUI

/// Groups rows into one white card with hairlines between them.
struct RowCard<Content: View>: View {
    @ViewBuilder var content: Content

    var body: some View {
        VStack(spacing: 0) { content }
            .card(padding: 0)
    }
}
