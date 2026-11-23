import SwiftUI

/// Confirming attendance at a hearing. A sheet rather than a full screen so the
/// client never loses the case behind it, and the checklist replaces the
/// instruction e-mail that today gets lost in an inbox.
struct HearingSheet: View {
    @Environment(AppState.self) private var appState
    @Environment(\.dismiss) private var dismiss

    let caseID: UUID
    let caseNumber: String
    let hearing: Hearing

    @State private var checklist: [ChecklistItem]
    @State private var isConfirming = false
    @State private var didConfirm = false
    @State private var showsError = false
    @State private var errorMessage = ""

    init(caseID: UUID, caseNumber: String, hearing: Hearing) {
        self.caseID = caseID
        self.caseNumber = caseNumber
        self.hearing = hearing
        _checklist = State(initialValue: hearing.checklist)
    }

    var body: some View {
        NavigationStack {
            Group {
                if didConfirm {
                    HearingConfirmedView(hearing: hearing, onClose: close)
                } else {
                    form
                }
            }
            .background(Theme.background)
            .navigationTitle(didConfirm ? Text(verbatim: "") : Text("hearing.title"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                if !didConfirm {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("common.close", action: close)
                    }
                }
            }
        }
        .presentationDetents([.large])
        // Fechar por arrasto no meio do envio deixaria o cliente sem saber se
        // a presença foi ou não registrada.
        .interactiveDismissDisabled(isConfirming)
        .sensoryFeedback(.success, trigger: didConfirm)
        .alert(Text("error.action.title"), isPresented: $showsError) {
            Button("common.tryAgain", action: confirm)
            Button("common.cancel", role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
    }

    private var form: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                VStack(spacing: 0) {
                    KeyValueRow(label: "hearing.when", value: Format.dateTime(hearing.date), isMono: true)
                    KeyValueRow(label: "hearing.where", value: "\(hearing.venue)\n\(hearing.address)")
                    KeyValueRow(
                        label: appState.isPersonalAccount ? "hearing.who.personal" : "hearing.who",
                        value: hearing.whoMustAttend
                    )
                }
                .padding(.bottom, 18)

                Text("hearing.bring")
                    .eyebrow()
                    .padding(.bottom, 10)
                    .accessibilityAddTraits(.isHeader)

                VStack(spacing: 0) {
                    ForEach($checklist) { $item in
                        Toggle(item.text, isOn: $item.isChecked)
                            .toggleStyle(ChecklistToggleStyle())
                    }
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 6)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Theme.fill, in: .rect(cornerRadius: 13))

                VStack(spacing: 8) {
                    Button(action: confirm) {
                        LoadingLabel("hearing.action.confirm", isLoading: isConfirming)
                    }
                    .buttonStyle(PrimaryButtonStyle())
                    .disabled(isConfirming)

                    WhatsAppButton(
                        context: .hearingConflict(caseNumber: caseNumber, hearingDate: hearing.date),
                        caseID: caseID,
                        titleKey: "hearing.action.cannotAttend"
                    )
                }
                .padding(.top, 20)
            }
            .sideMargin()
            .padding(.top, 16)
            .padding(.bottom, 28)
        }
    }

    private func close() {
        dismiss()
    }

    private func confirm() {
        guard !isConfirming else { return }
        isConfirming = true
        Task {
            defer { isConfirming = false }
            do {
                try await appState.confirmHearing(caseID: caseID)
                withAnimation { didConfirm = true }
            } catch {
                // Só diz "confirmada" quando o escritório de fato recebeu.
                errorMessage = appState.userMessage(for: error)
                showsError = true
            }
        }
    }
}

#Preview {
    HearingSheet(
        caseID: DemoDataset.current.hearingCaseID,
        caseNumber: "0012345-16.2025.5.17.0004",
        hearing: DemoDataset.current.cases.first { $0.id == DemoDataset.current.hearingCaseID }!.hearing!
    )
    .environment(AppState.signedInPreview())
}
