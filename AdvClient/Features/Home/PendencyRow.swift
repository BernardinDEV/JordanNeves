import SwiftUI

/// Uma pendência em "Exige você". Leva ao caso ou ao documento de que trata;
/// quando não aponta para nenhum dos dois, aparece sem se oferecer como link.
struct PendencyRow: View {
    let pendency: Pendency

    var body: some View {
        if let route = AppRoute(pendency: pendency) {
            NavigationLink(value: route) {
                row(showsChevron: true)
            }
            .buttonStyle(RowPressStyle())
        } else {
            row(showsChevron: false)
        }
    }

    private func row(showsChevron: Bool) -> AppListRow {
        AppListRow(
            title: pendency.title,
            subtitle: Format.deadline(pendency.dueDate),
            systemImage: pendency.kind.systemImage,
            iconTone: .critical,
            isMonoSubtitle: true,
            showsChevron: showsChevron
        )
    }
}
