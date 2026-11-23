import SwiftUI

struct RowDivider: View {
    var body: some View {
        Rectangle().fill(Theme.line).frame(height: 1).padding(.leading, 66)
    }
}
