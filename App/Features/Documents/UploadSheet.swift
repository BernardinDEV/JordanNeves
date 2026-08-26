import SwiftUI
import UniformTypeIdentifiers

/// Sending a file to the firm. Linking it to a case is required and pre-filled
/// from the case the client opened last — a loose document is a lost document.
struct UploadSheet: View {
    @Environment(AppState.self) private var appState
    @Environment(\.dismiss) private var dismiss

    @State private var pickedFileName: String?
    @State private var selectedCaseID: UUID?
    @State private var isImporting = false
    @State private var isSending = false
    @State private var progress: Double = 0

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    Text("upload.subtitle")
                        .font(Theme.font(14))
                        .foregroundStyle(Theme.muted)
                        .fixedSize(horizontal: false, vertical: true)

                    Button {
                        isImporting = true
                    } label: {
                        VStack(spacing: 5) {
                            Image(systemName: "arrow.up.doc")
                                .font(.system(size: 26, weight: .light))
                                .foregroundStyle(Theme.primary)
                            Text("upload.choose")
                                .font(Theme.font(15, weight: .semibold))
                                .foregroundStyle(Theme.primary)
                                .padding(.top, 5)
                            Text("upload.sources")
                                .font(Theme.font(12.5))
                                .foregroundStyle(Theme.muted)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(22)
                        .background(
                            RoundedRectangle(cornerRadius: Theme.Radius.card)
                                .strokeBorder(style: StrokeStyle(lineWidth: 1.5, dash: [6, 4]))
                                .foregroundStyle(Theme.line)
                        )
                    }
                    .buttonStyle(.plain)

                    if let pickedFileName {
                        HStack(spacing: 12) {
                            Image(systemName: "doc.text")
                                .font(.system(size: 17))
                                .foregroundStyle(Theme.primary)
                                .frame(width: 38, height: 38)
                                .background(.white, in: RoundedRectangle(cornerRadius: 10))
                            VStack(alignment: .leading, spacing: 5) {
                                Text(pickedFileName)
                                    .font(Theme.font(14, weight: .medium))
                                    .foregroundStyle(Theme.primary)
                                    .lineLimit(1)
                                if isSending {
                                    ProgressView(value: progress)
                                        .tint(Theme.primary)
                                }
                            }
                            Spacer(minLength: 0)
                        }
                        .padding(12)
                        .background(Theme.fill, in: RoundedRectangle(cornerRadius: 12))
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

                    Button {
                        send()
                    } label: {
                        if isSending {
                            ProgressView().tint(.white)
                        } else {
                            Text("upload.action.send")
                        }
                    }
                    .buttonStyle(PrimaryButtonStyle(isEnabled: pickedFileName != nil && !isSending))
                    .disabled(pickedFileName == nil || isSending)
                    .padding(.top, 4)
                }
                .sideMargin()
                .padding(.top, 12)
                .padding(.bottom, 28)
            }
            .background(Theme.background)
            .navigationTitle(Text("upload.title"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("common.close") { dismiss() }
                }
            }
        }
        .presentationDetents([.medium, .large])
        .fileImporter(
            isPresented: $isImporting,
            allowedContentTypes: [.pdf, .image, .plainText, .spreadsheet],
            allowsMultipleSelection: false
        ) { result in
            if case let .success(urls) = result, let url = urls.first {
                pickedFileName = url.lastPathComponent
            }
        }
        .onAppear {
            selectedCaseID = appState.casesRequiringClient.first?.id ?? appState.openCases.first?.id
        }
    }

    private func send() {
        guard let pickedFileName else { return }
        isSending = true
        Task {
            // Stand-in for a real multipart upload against a signed URL.
            for step in 1...10 {
                try? await Task.sleep(for: .milliseconds(70))
                progress = Double(step) / 10
            }
            await appState.upload(fileName: pickedFileName, caseID: selectedCaseID)
            isSending = false
            dismiss()
        }
    }
}

#Preview {
    UploadSheet().environment(AppState.signedInPreview())
}
