import SwiftUI

/// Um andamento em "Para saber". O ícone fica em latão enquanto não foi lido.
struct InformationalMovementRow: View {
    let item: MovementReference
    let isRead: Bool

    var body: some View {
        NavigationLink(value: AppRoute.movement(caseID: item.legalCase.id, movementID: item.movement.id)) {
            AppListRow(
                title: item.movement.displayHeadline,
                subtitle: subtitle,
                systemImage: "text.document",
                iconTone: isRead ? .neutral : .brass
            )
        }
        .buttonStyle(RowPressStyle())
    }

    private var subtitle: String {
        [
            Format.string(.init(item.legalCase.area.labelKey)),
            Format.date(item.movement.date),
            Format.string("notifications.nothingToDo"),
        ].joined(separator: " · ")
    }
}
