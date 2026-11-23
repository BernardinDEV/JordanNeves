import SwiftUI

/// Passo 1 do acesso: o e-mail convidado pelo escritório.
struct EmailStep: View {
    @Environment(AppState.self) private var appState
    @Binding var email: String
    let onCodeIssued: (CodeChallenge) -> Void

    @State private var isSending = false
    @State private var errorMessage: String?
    @FocusState private var focused: Bool

    private var canSubmit: Bool {
        MockAuthService.isPlausibleEmail(email) && !isSending
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                BrandMark()
                    .frame(width: 48, height: 48)
                    .padding(.top, 34)

                Text("login.title")
                    .font(Theme.font(32, weight: .bold))
                    .foregroundStyle(Theme.primary)
                    .padding(.top, 22)
                    .accessibilityAddTraits(.isHeader)

                Text("login.subtitle")
                    .font(Theme.font(15))
                    .foregroundStyle(Theme.muted)
                    .padding(.top, 6)
                    .fixedSize(horizontal: false, vertical: true)

                LabeledField(label: "login.field.email") {
                    TextField("login.field.email", text: $email, prompt: Text(verbatim: "nome@empresa.com.br"))
                        .textContentType(.emailAddress)
                        .keyboardType(.emailAddress)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .focused($focused)
                        .submitLabel(.go)
                        .onSubmit(submit)
                }
                .padding(.top, 22)

                if let errorMessage {
                    FieldErrorLabel(message: errorMessage)
                        .padding(.top, 10)
                }

                Button(action: submit) {
                    LoadingLabel("login.action.sendCode", isLoading: isSending)
                }
                .buttonStyle(PrimaryButtonStyle())
                .disabled(!canSubmit)
                .padding(.top, 12)

                Text("login.noPassword")
                    .font(Theme.font(12.5))
                    .foregroundStyle(Theme.muted)
                    .padding(.top, 16)
                    .fixedSize(horizontal: false, vertical: true)

                WhatsAppButton(context: .missingInvite, titleKey: "login.noInvite")
                    .padding(.top, 40)
                    .padding(.bottom, 20)
            }
            .sideMargin()
        }
        .scrollDismissesKeyboard(.interactively)
        .onAppear(perform: focusField)
    }

    private func focusField() {
        focused = true
    }

    private func submit() {
        guard canSubmit else { return }
        isSending = true
        withAnimation { errorMessage = nil }
        Task {
            defer { isSending = false }
            do {
                onCodeIssued(try await appState.requestCode(email: email))
            } catch {
                withAnimation { errorMessage = error.localizedDescription }
            }
        }
    }
}
