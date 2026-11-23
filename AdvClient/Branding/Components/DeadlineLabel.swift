import SwiftUI

/// A deadline always shows both the date and the countdown. The date alone forces
/// mental arithmetic; the countdown alone loses the reference.
struct DeadlineLabel: View {
    let date: Date
    var showsDate = true

    var body: some View {
        Text(showsDate ? Format.deadline(date) : Format.countdown(to: date))
            .font(Theme.mono(12))
            .foregroundStyle(Theme.muted)
    }
}
