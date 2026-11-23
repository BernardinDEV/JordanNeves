import SwiftUI

/// Passo 2 do acesso: o código de seis dígitos enviado por e-mail.
struct CodeStep: View {
    @Environment(AppState.self) private var appState
    let challenge: CodeChallenge
    let onResend: (CodeChallenge) -> Void

    @State private var code = ""
    @State private var isVerifying = false
    @State private var errorMessage: String?
    @State private var secondsLeft = 0
    @FocusState private var focused: Bool

    private let digitCount = 6

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                Text("code.title")
                    .font(Theme.font(26, weight: .bold))
                    .foregroundStyle(Theme.primary)
                    .padding(.top, 12)
                    .accessibilityAddTraits(.isHeader)

                Text("code.sentTo \(challenge.email)")
                    .font(Theme.font(15))
                    .foregroundStyle(Theme.muted)
                    .padding(.top, 8)
                    .fixedSize(horizontal: false, vertical: true)

                OneTimeCodeField(code: $code, digitCount: digitCount, isFocused: $focused)
                    .padding(.top, 26)
                    .onChange(of: code) { _, newValue in
                        codeChanged(to: newValue)
                    }

                if let errorMessage {
                    FieldErrorLabel(message: errorMessage)
                        .padding(.top, 14)
                }

                Button(action: verify) {
                    LoadingLabel("code.action.confirm", isLoading: isVerifying)
                }
                .buttonStyle(PrimaryButtonStyle())
                .disabled(code.count != digitCount || isVerifying)
                .padding(.top, 24)

                Group {
                    if secondsLeft > 0 {
                        Text("code.resendIn \(secondsLeft)")
                            .font(Theme.mono(12.5))
                            .foregroundStyle(Theme.muted)
                            .frame(minHeight: Theme.minTouchTarget)
                    } else {
                        Button("code.resend", action: resend)
                            .buttonStyle(LinkButtonStyle())
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.top, 8)

                #if DEBUG
                Text("code.demoHint \(MockAuthService.demoCode)")
                    .font(Theme.mono(11))
                    .foregroundStyle(Theme.brass)
                    .frame(maxWidth: .infinity)
                    .padding(.top, 4)
                #endif
            }
            .sideMargin()
        }
        .navigationTitle(Text("code.navTitle"))
        .navigationBarTitleDisplayMode(.inline)
        .onAppear(perform: focusField)
        .task(id: challenge.resendAllowedAt) {
            await countDownToResend()
        }
    }

    private func focusField() {
        focused = true
        secondsLeft = challenge.secondsUntilResend()
    }

    private func countDownToResend() async {
        while !Task.isCancelled {
            secondsLeft = challenge.secondsUntilResend()
            if secondsLeft == 0 { break }
            try? await Task.sleep(for: .seconds(1))
        }
    }

    private func codeChanged(to newValue: String) {
        let digits = String(newValue.filter(\.isNumber).prefix(digitCount))
        if digits != newValue {
            code = digits
            return
        }
        if !digits.isEmpty {
            withAnimation { errorMessage = nil }
        }
        // Advances on its own at the sixth digit; the button exists only for
        // people who would rather confirm.
        if digits.count == digitCount { verify() }
    }

    private func verify() {
        guard !isVerifying, code.count == digitCount else { return }
        isVerifying = true
        Task {
            defer { isVerifying = false }
            do {
                // Nada a fazer depois daqui: `verify` grava a empresa, o que
                // leva `phase` a `.ready` e troca a árvore de views. O convite
                // ao Face ID vive na MainTabView, já do outro lado da troca.
                try await appState.verify(code: code, challenge: challenge)
            } catch {
                code = ""
                withAnimation { errorMessage = error.localizedDescription }
            }
        }
    }

    private func resend() {
        Task {
            do {
                onResend(try await appState.requestCode(email: challenge.email))
            } catch {
                withAnimation { errorMessage = error.localizedDescription }
            }
        }
    }
}
