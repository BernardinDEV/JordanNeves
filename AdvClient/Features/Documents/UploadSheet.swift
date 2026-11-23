import SwiftUI
import UniformTypeIdentifiers

/// Sending a file to the firm. Linking it to a case is required and pre-filled
/// from the case the client opened last — a loose document is a lost document.
struct UploadSheet: View {
    @Environment(AppState.self) private var appState
    @Environment(\.dismiss) private var dismiss

    @State private var pickedFile: UploadFile?
    @State private var selectedCaseID: UUID?
    @State private var isImporting = false
    @State private var isSending = false
    @State private var didSend = false
    @State private var progress: Double = 0
    @State private var showsError = false
    @State private var errorMessage = ""
    /// Falha no envio pode ser repetida; arquivo ilegível ou grande demais, não.
    @State private var canRetry = false

    var body: some View {
        NavigationStack {
            Group {
                if didSend {
                    UploadSentView(fileName: pickedFile?.name ?? "", onClose: close)
                } else {
                    form
                }
            }
            .background(Theme.background)
            .navigationTitle(didSend ? Text(verbatim: "") : Text("upload.title"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                if !didSend {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("common.close", action: close)
                    }
                }
            }
        }
        .presentationDetents([.medium, .large])
        // Fechar por arrasto no meio do envio deixaria o cliente sem saber se
        // o arquivo chegou.
        .interactiveDismissDisabled(isSending)
        .sensoryFeedback(.success, trigger: didSend)
        .fileImporter(
            isPresented: $isImporting,
            allowedContentTypes: [.pdf, .image, .plainText, .spreadsheet],
            allowsMultipleSelection: false,
            onCompletion: didPickFile
        )
        .alert(Text("error.action.title"), isPresented: $showsError) {
            if canRetry {
                Button("common.tryAgain", action: send)
                Button("common.cancel", role: .cancel) {}
            } else {
                Button("common.ok", role: .cancel) {}
            }
        } message: {
            Text(errorMessage)
        }
        .onAppear(perform: preselectCase)
    }

    private var form: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                Text("upload.subtitle")
                    .font(Theme.font(14))
                    .foregroundStyle(Theme.muted)
                    .fixedSize(horizontal: false, vertical: true)

                Button(action: chooseFile) {
                    UploadDropZone()
                }
                .buttonStyle(CardPressStyle())
                .disabled(isSending)

                if let pickedFile {
                    PickedFileRow(fileName: pickedFile.name, progress: isSending ? progress : nil)
                }

                LabeledField(label: "upload.forCase") {
                    Picker("upload.forCase", selection: $selectedCaseID) {
                        Text("upload.noCase").tag(UUID?.none)
                        ForEach(appState.openCases) { legalCase in
                            Text(legalCase.title).tag(UUID?.some(legalCase.id))
                        }
                    }
                    .labelsHidden()
                    .pickerStyle(.menu)
                    .tint(Theme.primary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .disabled(isSending)

                Button(action: send) {
                    LoadingLabel("upload.action.send", isLoading: isSending)
                }
                .buttonStyle(PrimaryButtonStyle())
                .disabled(pickedFile == nil || isSending)
                .padding(.top, 4)
            }
            .sideMargin()
            .padding(.top, 12)
            .padding(.bottom, 28)
        }
    }

    private func close() {
        dismiss()
    }

    private func chooseFile() {
        isImporting = true
    }

    private func didPickFile(_ result: Result<[URL], Error>) {
        guard case let .success(urls) = result, let url = urls.first else { return }
        do {
            let file = try UploadFile(contentsOf: url)
            guard file.data.count <= UploadFile.maxBytes else {
                show(Format.string("upload.error.tooLarge"))
                return
            }
            pickedFile = file
        } catch {
            show(Format.string("upload.error.unreadable"))
        }
    }

    private func show(_ message: String, canRetry: Bool = false) {
        errorMessage = message
        self.canRetry = canRetry
        showsError = true
    }

    private func preselectCase() {
        selectedCaseID = appState.casesRequiringClient.first?.id ?? appState.openCases.first?.id
    }

    private func send() {
        guard let pickedFile, !isSending else { return }
        isSending = true
        progress = 0
        Task {
            defer { isSending = false }
            // Progresso indicativo: `URLSession` com `data(for:)` não reporta
            // bytes enviados. Trocar por `upload(for:from:delegate:)` quando o
            // backend existir dá a barra real.
            for step in 1...9 {
                try? await Task.sleep(for: .milliseconds(70))
                progress = Double(step) / 10
            }
            do {
                try await appState.upload(pickedFile, caseID: selectedCaseID)
                // A confirmação diz o que vem a seguir — fechar a folha em
                // silêncio deixava o cliente sem saber se o arquivo chegou.
                withAnimation { didSend = true }
            } catch {
                show(appState.userMessage(for: error), canRetry: true)
            }
        }
    }
}

#Preview {
    UploadSheet().environment(AppState.signedInPreview())
}
