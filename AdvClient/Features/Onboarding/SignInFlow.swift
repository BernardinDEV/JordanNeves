import SwiftUI

/// Sign-in has three steps and no password: e-mail, six-digit code, then the
/// optional Face ID opt-in. Clients are invited by the firm, so there is no
/// account creation — and nothing to forget.
struct SignInFlow: View {
    @Environment(AppState.self) private var appState
    @State private var step: Step = .email
    @State private var email = ""
    @State private var challenge: CodeChallenge?

    private enum Step: Equatable { case email, code, biometrics }

    var body: some View {
        NavigationStack {
            Group {
                switch step {
                case .email:
                    EmailStep(email: $email) { issued in
                        challenge = issued
                        withAnimation { step = .code }
                    }
                case .code:
                    if let challenge {
                        CodeStep(challenge: challenge) {
                            withAnimation { step = .email }
                        } onVerified: {
                            if appState.canUseBiometrics && !appState.didAskBiometrics {
                                withAnimation { step = .biometrics }
                            }
                        } onResend: { reissued in
                            self.challenge = reissued
                        }
                    }
                case .biometrics:
                    BiometricOptInStep()
                }
            }
            .background(Theme.background.ignoresSafeArea())
        }
    }
}

// MARK: - Step 1 · e-mail

private struct EmailStep: View {
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
                CompassRose()
                    .frame(width: 48, height: 48)
                    .tint(Theme.primary)
                    .padding(.top, 34)

                Text("login.title")
                    .font(Theme.font(32, weight: .bold))
                    .foregroundStyle(Theme.primary)
                    .padding(.top, 22)

                Text("login.subtitle")
                    .font(Theme.font(15))
                    .foregroundStyle(Theme.muted)
                    .padding(.top, 6)
                    .fixedSize(horizontal: false, vertical: true)

                LabeledField(label: "login.field.email") {
                    TextField("", text: $email, prompt: Text(verbatim: "nome@empresa.com.br"))
                        .textContentType(.emailAddress)
                        .keyboardType(.emailAddress)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .focused($focused)
                        .submitLabel(.go)
                        .onSubmit { if canSubmit { submit() } }
                }
                .padding(.top, 22)

                if let errorMessage {
                    Label(errorMessage, systemImage: "exclamationmark.circle")
                        .font(Theme.font(13))
                        .foregroundStyle(Theme.critical)
                        .padding(.top, 10)
                        .transition(.opacity)
                }

                Button {
                    submit()
                } label: {
                    if isSending {
                        ProgressView().tint(Theme.onBrand)
                    } else {
                        Text("login.action.sendCode")
                    }
                }
                .buttonStyle(PrimaryButtonStyle(isEnabled: canSubmit))
                .disabled(!canSubmit)
                .padding(.top, 12)

                Text("login.noPassword")
                    .font(Theme.font(12.5))
                    .foregroundStyle(Theme.muted)
                    .padding(.top, 16)
                    .fixedSize(horizontal: false, vertical: true)

                Spacer(minLength: 40)

                WhatsAppButton(context: .missingInvite, titleKey: "login.noInvite")
                    .padding(.bottom, 20)
            }
            .sideMargin()
        }
        .scrollDismissesKeyboard(.interactively)
        .onAppear { focused = true }
    }

    private func submit() {
        isSending = true
        withAnimation { errorMessage = nil }
        Task {
            do {
                let challenge = try await appState.requestCode(email: email)
                isSending = false
                onCodeIssued(challenge)
            } catch {
                isSending = false
                withAnimation { errorMessage = error.localizedDescription }
            }
        }
    }
}

// MARK: - Step 2 · code

private struct CodeStep: View {
    @Environment(AppState.self) private var appState
    let challenge: CodeChallenge
    let onBack: () -> Void
    let onVerified: () -> Void
    let onResend: (CodeChallenge) -> Void

    @State private var code = ""
    @State private var isVerifying = false
    @State private var errorMessage: String?
    @State private var secondsLeft: Int = 0
    @FocusState private var focused: Bool

    private let digitCount = 6

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                Text("code.title")
                    .font(Theme.font(26, weight: .bold))
                    .foregroundStyle(Theme.primary)
                    .padding(.top, 12)

                Text("code.sentTo \(challenge.email)")
                    .font(Theme.font(15))
                    .foregroundStyle(Theme.muted)
                    .padding(.top, 8)
                    .fixedSize(horizontal: false, vertical: true)

                // A single hidden field backs six boxes: iOS one-time-code
                // autofill works, and there is no focus juggling between six
                // separate inputs.
                ZStack {
                    TextField("", text: $code)
                        .keyboardType(.numberPad)
                        .textContentType(.oneTimeCode)
                        .focused($focused)
                        .opacity(0.001)
                        .accessibilityLabel(Text("code.field.a11y"))

                    HStack(spacing: 8) {
                        ForEach(0..<digitCount, id: \.self) { index in
                            digitBox(at: index)
                        }
                    }
                    .allowsHitTesting(false)
                }
                .contentShape(.rect)
                .onTapGesture { focused = true }
                .padding(.top, 26)
                .onChange(of: code) { _, newValue in
                    let digits = String(newValue.filter(\.isNumber).prefix(digitCount))
                    if digits != newValue { code = digits }
                    withAnimation { errorMessage = nil }
                    // Advances on its own at the sixth digit; the button exists
                    // only for people who would rather confirm.
                    if digits.count == digitCount { verify() }
                }

                if let errorMessage {
                    Label(errorMessage, systemImage: "exclamationmark.circle")
                        .font(Theme.font(13))
                        .foregroundStyle(Theme.critical)
                        .padding(.top, 14)
                        .transition(.opacity)
                }

                Button {
                    verify()
                } label: {
                    if isVerifying {
                        ProgressView().tint(Theme.onBrand)
                    } else {
                        Text("code.action.confirm")
                    }
                }
                .buttonStyle(PrimaryButtonStyle(isEnabled: code.count == digitCount && !isVerifying))
                .disabled(code.count != digitCount || isVerifying)
                .padding(.top, 24)

                Group {
                    if secondsLeft > 0 {
                        Text("code.resendIn \(secondsLeft)")
                    } else {
                        Button("code.resend") { resend() }
                            .font(Theme.font(13, weight: .semibold))
                            .foregroundStyle(Theme.primary)
                    }
                }
                .font(Theme.mono(12.5))
                .foregroundStyle(Theme.muted)
                .frame(maxWidth: .infinity)
                .frame(minHeight: Theme.minTouchTarget)
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
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button { onBack() } label: {
                    Image(systemName: "chevron.left")
                }
                .accessibilityLabel(Text("common.back"))
            }
        }
        .onAppear {
            focused = true
            secondsLeft = challenge.secondsRemaining()
        }
        .task(id: challenge.expiresAt) {
            while !Task.isCancelled {
                secondsLeft = challenge.secondsRemaining()
                if secondsLeft == 0 { break }
                try? await Task.sleep(for: .seconds(1))
            }
        }
    }

    private func digitBox(at index: Int) -> some View {
        let digits = Array(code)
        let isCursor = index == digits.count
        return Text(index < digits.count ? String(digits[index]) : " ")
            .font(Theme.mono(24, weight: .medium))
            .foregroundStyle(Theme.primary)
            .frame(maxWidth: .infinity, minHeight: 58)
            .background(Theme.card, in: RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isCursor && focused ? Theme.primary : Theme.line, lineWidth: isCursor && focused ? 2 : 1)
            )
    }

    private func verify() {
        guard !isVerifying else { return }
        isVerifying = true
        Task {
            do {
                try await appState.verify(code: code, challenge: challenge)
                isVerifying = false
                onVerified()
            } catch {
                isVerifying = false
                code = ""
                withAnimation { errorMessage = error.localizedDescription }
            }
        }
    }

    private func resend() {
        Task {
            if let reissued = try? await appState.requestCode(email: challenge.email) {
                onResend(reissued)
                secondsLeft = reissued.secondsRemaining()
            }
        }
    }
}

// MARK: - Step 3 · Face ID

/// Asked *after* the first successful sign-in, with the reason next to it.
/// Asking before is the classic mistake: the user declines and never finds the
/// setting again.
private struct BiometricOptInStep: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            Image(systemName: "faceid")
                .font(.system(size: 46, weight: .light))
                .foregroundStyle(Theme.primary)
                .frame(width: 96, height: 96)
                .background(Theme.fill, in: RoundedRectangle(cornerRadius: 26))

            Text("biometric.optIn.title \(appState.biometryName)")
                .font(Theme.font(24, weight: .bold))
                .foregroundStyle(Theme.primary)
                .multilineTextAlignment(.center)
                .padding(.top, 26)
                .fixedSize(horizontal: false, vertical: true)

            Text("biometric.optIn.body")
                .font(Theme.font(15))
                .foregroundStyle(Theme.muted)
                .multilineTextAlignment(.center)
                .padding(.top, 10)
                .fixedSize(horizontal: false, vertical: true)

            Spacer()

            VStack(spacing: 8) {
                Button("biometric.optIn.enable \(appState.biometryName)") {
                    appState.setBiometricEnabled(true)
                }
                .buttonStyle(PrimaryButtonStyle())

                Button("biometric.optIn.later") {
                    appState.markBiometricsAsked()
                }
                .font(Theme.font(15, weight: .semibold))
                .foregroundStyle(Theme.primary)
                .frame(minHeight: Theme.minTouchTarget)
            }
            .padding(.bottom, 20)
        }
        .sideMargin()
        .navigationBarBackButtonHidden()
    }
}

#Preview {
    SignInFlow().environment(AppState())
}
