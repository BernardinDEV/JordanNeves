import SwiftUI

struct ProfileView: View {
    @Environment(AppState.self) private var appState
    @State private var showLogoutConfirmation = false

    var body: some View {
        @Bindable var appState = appState

        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    avatar

                    VStack(alignment: .leading, spacing: 12) {
                        Text("profile.section.personal")
                            .font(Theme.font(13, weight: .semibold))
                            .foregroundStyle(Theme.muted)
                            .textCase(.uppercase)
                        InfoRow(labelKey: "profile.name", value: appState.client?.name ?? "—")
                        Divider()
                        InfoRow(labelKey: "profile.cpf", value: appState.client?.cpf ?? "—")
                        Divider()
                        InfoRow(labelKey: "profile.email", value: appState.client?.email ?? "—")
                        Divider()
                        InfoRow(labelKey: "profile.phone", value: appState.client?.phone ?? "—")
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .card()

                    VStack(alignment: .leading, spacing: 12) {
                        Text("profile.section.preferences")
                            .font(Theme.font(13, weight: .semibold))
                            .foregroundStyle(Theme.muted)
                            .textCase(.uppercase)

                        Picker("profile.language", selection: $appState.language) {
                            ForEach(AppLanguage.allCases) { lang in
                                Text(lang.labelKey).tag(lang)
                            }
                        }
                        .pickerStyle(.segmented)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .card()

                    if appState.canUseBiometrics {
                        securitySection
                    }

                    Button(role: .destructive) {
                        showLogoutConfirmation = true
                    } label: {
                        Text("profile.logout")
                            .font(Theme.font(16, weight: .semibold))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                    }
                    .background(.red.opacity(0.08))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .padding(20)
            }
            .background(Theme.background)
            .navigationTitle("profile.title")
            .confirmationDialog("profile.logout.confirm", isPresented: $showLogoutConfirmation, titleVisibility: .visible) {
                Button("profile.logout", role: .destructive) { appState.logout() }
                Button("common.cancel", role: .cancel) {}
            }
        }
    }

    private var securitySection: some View {
        @Bindable var appState = appState
        return VStack(alignment: .leading, spacing: 8) {
            Text("profile.section.security")
                .font(Theme.font(13, weight: .semibold))
                .foregroundStyle(Theme.muted)
                .textCase(.uppercase)

            Toggle(isOn: Binding(
                get: { appState.biometricEnabled },
                set: { appState.setBiometricEnabled($0) }
            )) {
                // Interpolated LocalizedStringKey so it resolves against the
                // in-app language (environment locale), not the system one.
                Text("profile.biometric \(appState.biometryName)")
                    .font(Theme.font(15))
                    .foregroundStyle(Theme.primary)
            }
            .tint(Theme.primary)

            Text("profile.biometric.footer \(appState.biometryName)")
                .font(Theme.font(12))
                .foregroundStyle(Theme.muted)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .card()
    }

    private var avatar: some View {
        VStack(spacing: 10) {
            Text(appState.client?.initials ?? "?")
                .font(Theme.font(30, weight: .bold))
                .foregroundStyle(.white)
                .frame(width: 88, height: 88)
                .background(Theme.primary)
                .clipShape(Circle())
            Text(appState.client?.name ?? "")
                .font(Theme.font(18, weight: .semibold))
                .foregroundStyle(Theme.primary)
            Text("profile.clientSince")
                .font(Theme.font(12))
                .foregroundStyle(Theme.muted)
        }
        .padding(.top, 8)
    }
}

#Preview {
    ProfileView().environment(AppState.loggedInPreview())
}
