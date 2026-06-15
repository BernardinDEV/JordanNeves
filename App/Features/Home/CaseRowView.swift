import SwiftUI

struct CaseRowView: View {
    let legalCase: LegalCase

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top) {
                Image(systemName: legalCase.area.systemImage)
                    .font(.system(size: 17))
                    .foregroundStyle(Theme.primary)
                    .frame(width: 38, height: 38)
                    .background(Theme.primary.opacity(0.08))
                    .clipShape(RoundedRectangle(cornerRadius: 10))

                VStack(alignment: .leading, spacing: 3) {
                    Text(LocalizedStringKey(legalCase.titleKey))
                        .font(Theme.font(15, weight: .semibold))
                        .foregroundStyle(Theme.primary)
                        .lineLimit(2)
                    Text(legalCase.number)
                        .font(Theme.font(12))
                        .foregroundStyle(Theme.muted)
                        .lineLimit(1)
                }

                Spacer(minLength: 8)

                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Theme.secondary)
            }

            HStack {
                StatusBadge(status: legalCase.status)
                Spacer()
                Text("case.updated \(legalCase.lastUpdate.formatted(date: .abbreviated, time: .omitted))")
                    .font(Theme.font(12))
                    .foregroundStyle(Theme.muted)
            }
        }
        .card()
    }
}

struct StatusBadge: View {
    let status: CaseStatus

    private var color: Color {
        switch status {
        case .active: .blue
        case .awaitingDecision: .orange
        case .appeal: .purple
        case .settled, .closed: .green
        }
    }

    var body: some View {
        Text(LocalizedStringKey(status.labelKey))
            .font(Theme.font(11, weight: .semibold))
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(color.opacity(0.12))
            .foregroundStyle(color)
            .clipShape(Capsule())
    }
}
