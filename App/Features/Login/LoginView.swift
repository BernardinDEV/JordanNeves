import SwiftUI

struct LoginView: View {
    @Environment(AppState.self) private var appState

    @State private var identifier = ""
    @State private var password = ""
    @State private var isLoading = false
    @State private var errorMessage: String?

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                Image("LogoVertical")
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: 220)
                    .padding(.top, 70)
                    .padding(.bottom, 12)

                Text("brand.tagline")
                    .font(Theme.font(14))
                    .foregroundStyle(Theme.muted)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
                    .padding(.bottom, 40)

                VStack(spacing: 16) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("login.identifier")
                            .font(Theme.font(13, weight: .semibold))
                            .foregroundStyle(Theme.primary)
                        TextField("login.identifier.placeholder", text: $identifier)
                            .textContentType(.username)
                            .keyboardType(.emailAddress)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                            .loginFieldStyle()
                    }

                    VStack(alignment: .leading, spacing: 6) {
                        Text("login.password")
                            .font(Theme.font(13, weight: .semibold))
                            .foregroundStyle(Theme.primary)
                        SecureField("login.password.placeholder", text: $password)
                            .textContentType(.password)
                            .loginFieldStyle()
                    }

                    if let errorMessage {
                        Text(errorMessage)
                            .font(Theme.font(13))
                            .foregroundStyle(.red)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }

                    Button {
                        Task { await login() }
                    } label: {
                        if isLoading {
                            ProgressView().tint(.white)
                        } else {
                            Text("login.submit")
                        }
                    }
                    .buttonStyle(PrimaryButtonStyle())
                    .disabled(isLoading)

                    Button("login.forgotPassword") {
                        // TODO: password recovery flow
                    }
                    .font(Theme.font(14, weight: .medium))
                    .foregroundStyle(Theme.primary)
                    .padding(.top, 4)
                }
                .padding(.horizontal, 28)
            }
        }
        .scrollBounceBehavior(.basedOnSize)
        .background(Theme.background)
    }

    private func login() async {
        errorMessage = nil
        isLoading = true
        defer { isLoading = false }
        do {
            try await appState.login(identifier: identifier, password: password)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

private struct LoginFieldStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(Theme.font(16))
            .foregroundStyle(Theme.primary)
            .tint(Theme.primary)
            .padding(14)
            .background(.white)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Theme.primary.opacity(0.35), lineWidth: 1.5)
            )
            .shadow(color: Theme.primary.opacity(0.08), radius: 6, y: 2)
    }
}

private extension View {
    func loginFieldStyle() -> some View { modifier(LoginFieldStyle()) }
}

#Preview {
    LoginView().environment(AppState())
}
