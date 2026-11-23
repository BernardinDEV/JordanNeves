import SwiftUI

/// Sign-in has three steps and no password: e-mail, six-digit code, then the
/// optional Face ID opt-in. Clients are invited by the firm, so there is no
/// account creation — and nothing to forget.
///
/// O passo do código é **empilhado** na navegação, não trocado no lugar: o
/// botão de voltar e o gesto de arrastar da borda são os do sistema.
struct SignInFlow: View {
    @State private var email = ""
    @State private var challenge: CodeChallenge?
    @State private var isShowingCode = false

    var body: some View {
        NavigationStack {
            EmailStep(email: $email, onCodeIssued: showCode)
                .background(Theme.background)
                .navigationDestination(isPresented: $isShowingCode) {
                    if let challenge {
                        CodeStep(challenge: challenge, onResend: replaceChallenge)
                            .background(Theme.background)
                    }
                }
        }
    }

    private func showCode(for issued: CodeChallenge) {
        challenge = issued
        isShowingCode = true
    }

    private func replaceChallenge(with reissued: CodeChallenge) {
        challenge = reissued
    }
}

#Preview {
    SignInFlow().environment(AppState())
}
