import SwiftUI

struct CaseDetailView: View {
    let legalCase: LegalCase

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                header
                infoCard
                timeline
            }
            .padding(20)
        }
        .background(Theme.background)
        .navigationTitle("caseDetail.title")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(LocalizedStringKey(legalCase.titleKey))
                .font(Theme.font(20, weight: .bold))
                .foregroundStyle(Theme.primary)
            HStack {
                StatusBadge(status: legalCase.status)
                Text(LocalizedStringKey(legalCase.area.labelKey))
                    .font(Theme.font(12, weight: .medium))
                    .foregroundStyle(Theme.muted)
            }
        }
    }

    private var infoCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            InfoRow(labelKey: "caseDetail.number", value: legalCase.number)
            Divider()
            InfoRow(labelKey: "caseDetail.court", value: legalCase.court)
            Divider()
            InfoRow(labelKey: "caseDetail.lawyer", value: legalCase.responsibleLawyer)
            Divider()
            InfoRow(labelKey: "caseDetail.openedAt", value: legalCase.openedAt.formatted(date: .long, time: .omitted))
        }
        .card()
    }

    private var timeline: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("caseDetail.timeline")
                .font(Theme.font(18, weight: .bold))
                .foregroundStyle(Theme.primary)

            ForEach(Array(legalCase.movements.enumerated()), id: \.element.id) { index, movement in
                HStack(alignment: .top, spacing: 14) {
                    VStack(spacing: 0) {
                        Circle()
                            .fill(index == 0 ? Theme.primary : Theme.secondary)
                            .frame(width: 12, height: 12)
                        if index < legalCase.movements.count - 1 {
                            Rectangle()
                                .fill(Theme.secondary.opacity(0.5))
                                .frame(width: 2)
                                .frame(maxHeight: .infinity)
                        }
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text(movement.date.formatted(date: .abbreviated, time: .omitted))
                            .font(Theme.font(12, weight: .medium))
                            .foregroundStyle(Theme.muted)
                        Text(LocalizedStringKey(movement.titleKey))
                            .font(Theme.font(15, weight: .semibold))
                            .foregroundStyle(Theme.primary)
                        Text(LocalizedStringKey(movement.detailKey))
                            .font(Theme.font(13))
                            .foregroundStyle(Theme.muted)
                    }
                    .padding(.bottom, 18)
                }
                .fixedSize(horizontal: false, vertical: true)
            }
        }
        .card()
    }
}

struct InfoRow: View {
    let labelKey: LocalizedStringKey
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(labelKey)
                .font(Theme.font(12, weight: .medium))
                .foregroundStyle(Theme.muted)
            Text(value)
                .font(Theme.font(15))
                .foregroundStyle(Theme.primary)
        }
    }
}
