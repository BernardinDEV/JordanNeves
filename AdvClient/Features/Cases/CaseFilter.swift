import SwiftUI

/// O recorte da lista de casos.
enum CaseFilter: CaseIterable, Identifiable {
    case active, closed, all

    var id: Self { self }

    var labelKey: LocalizedStringKey {
        switch self {
        case .active: "cases.filter.active"
        case .closed: "cases.filter.closed"
        case .all: "cases.filter.all"
        }
    }
}
