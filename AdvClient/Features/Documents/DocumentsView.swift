import SwiftUI

/// The repository, treated as a calendar of deadlines that happens to hold files.
/// "Precisa de você" sits above the search box — nobody opens an app to browse
/// forty-one PDFs.
struct DocumentsView: View {
    @Environment(AppState.self) private var appState
    @State private var kind: DocumentKind = .contract
    @State private var query = ""
    @State private var showUpload = false

    private var filtered: [ClientDocument] {
        let byKind = appState.documents.filter { $0.kind == kind }
        let trimmed = query.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return byKind }
        return byKind.filter {
            $0.title.localizedCaseInsensitiveContains(trimmed)
                || ($0.counterparty ?? "").localizedCaseInsensitiveContains(trimmed)
        }
    }

    private var attention: [ClientDocument] {
        query.isEmpty ? appState.documentsNeedingAttention : []
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: 0) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("docs.title")
                            .font(Theme.font(34, weight: .bold))
                            .foregroundStyle(Theme.primary)
                        Text("docs.count \(appState.contracts.count) \(appState.documents.count)")
                            .font(Theme.font(14))
                            .foregroundStyle(Theme.muted)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .sideMargin()
                    .padding(.top, 14)
                    .padding(.bottom, 14)

                    Picker("docs.kind", selection: $kind) {
                        ForEach(DocumentKind.allCases, id: \.self) { option in
                            Text(LocalizedStringKey(option.labelKey)).tag(option)
                        }
                    }
                    .pickerStyle(.segmented)
                    .sideMargin()

                    if !attention.isEmpty {
                        SectionHeader("docs.section.needsYou")
                        VStack(spacing: 9) {
                            ForEach(attention) { document in
                                NavigationLink(value: document.id) {
                                    attentionCard(document)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .sideMargin()
                    }

                    SectionHeader(LocalizedStringKey(kind == .contract ? "docs.section.allContracts" : "docs.section.allFiles"))

                    if filtered.isEmpty {
                        EmptyStateView(
                            systemImage: "folder",
                            title: "docs.empty.title",
                            message: "docs.empty.message"
                        )
                        .card()
                        .sideMargin()
                    } else {
                        RowCard {
                            ForEach(Array(filtered.enumerated()), id: \.element.id) { index, document in
                                NavigationLink(value: document.id) {
                                    row(document)
                                }
                                .buttonStyle(.plain)
                                if index < filtered.count - 1 { RowDivider() }
                            }
                        }
                        .sideMargin()
                    }
                }
                .padding(.bottom, 90)
            }
            .background(Theme.background)
            .searchable(text: $query, prompt: Text("docs.searchPrompt"))
            .refreshable { await appState.refresh() }
            .navigationDestination(for: UUID.self) { ContractDetailView(documentID: $0) }
            .toolbar(.hidden, for: .navigationBar)
            .overlay(alignment: .bottomTrailing) {
                Button {
                    showUpload = true
                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundStyle(Theme.onBrand)
                        .frame(width: 54, height: 54)
                        .background(Theme.primary, in: RoundedRectangle(cornerRadius: 17))
                        .shadow(color: Theme.primary.opacity(0.28), radius: 10, y: 4)
                }
                .padding(.trailing, 18)
                .padding(.bottom, 18)
                .accessibilityLabel(Text("docs.upload.a11y"))
            }
            .sheet(isPresented: $showUpload) { UploadSheet() }
        }
    }

    private func attentionCard(_ document: ClientDocument) -> some View {
        let alert = appState.contractAlert(for: document)
        let isUrgent = alert == .urgent
        return HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 3) {
                Text(document.title)
                    .font(Theme.font(14.5, weight: .semibold))
                    .foregroundStyle(Theme.primary)
                    .multilineTextAlignment(.leading)
                if let deadline = document.effectiveDeadline {
                    Text(document.autoRenews
                         ? String(localized: "docs.noticeBy \(Format.deadline(deadline))")
                         : Format.deadline(deadline))
                        .font(Theme.mono(12))
                        .foregroundStyle(Theme.muted)
                }
            }
            Spacer(minLength: 8)
            StatePill(
                String(localized: document.autoRenews ? "docs.action.decide" : "docs.action.renew"),
                tone: isUrgent ? .critical : .attention
            )
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 13)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.card)
        .overlay(alignment: .leading) {
            Rectangle().fill(isUrgent ? Theme.critical : Theme.attention).frame(width: 3)
        }
        .clipShape(RoundedRectangle(cornerRadius: 13))
        .shadow(color: Theme.primary.opacity(0.06), radius: 8, y: 3)
    }

    private func row(_ document: ClientDocument) -> some View {
        let alert = appState.contractAlert(for: document)
        let pill: (String, StatePill.Tone)? = {
            guard document.kind == .contract else { return nil }
            switch alert {
            case .urgent: return (String(localized: "docs.action.decide"), .critical)
            case .decide: return (String(localized: "docs.action.renew"), .attention)
            case .watch, nil: return (String(localized: "state.onTrack"), .onTrack)
            }
        }()
        return AppListRow(
            title: document.title,
            subtitle: subtitle(for: document),
            systemImage: document.uploadedByClient ? "arrow.up.doc" : "doc.text",
            isMonoSubtitle: true,
            trailingPill: pill.map { (text: $0.0, tone: $0.1) }
        )
    }

    private func subtitle(for document: ClientDocument) -> String {
        if let expiry = document.expiresAt {
            return String(localized: "docs.validUntil \(Format.date(expiry))")
        }
        return String(localized: "docs.uploadedOn \(Format.date(document.uploadedAt))")
    }
}

#Preview {
    DocumentsView().environment(AppState.signedInPreview())
}
