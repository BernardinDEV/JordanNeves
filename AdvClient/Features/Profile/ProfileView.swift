import SwiftUI

/// Account, security and the firm. Fees sit here in plain sight: hiding what the
/// client owes is what produces the awkward phone call.
struct ProfileView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.openURL) private var openURL
    @State private var showSignOutConfirm = false
    @State private var showDeleteInfo = false

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: 0) {
                    Text("profile.title")
                        .font(Theme.font(34, weight: .bold))
                        .foregroundStyle(Theme.primary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .sideMargin()
                        .padding(.top, 14)
                        .padding(.bottom, 16)

                    companyCard

                    SectionHeader("profile.section.account")
                    RowCard {
                        AppListRow(
                            title: Format.string("profile.users"),
                            subtitle: Format.string("profile.users.count \(3)"),
                            systemImage: "person.2"
                        )
                        RowDivider()
                        AppListRow(
                            title: Format.string("profile.notifications"),
                            subtitle: Format.string("profile.notifications.value"),
                            systemImage: "bell"
                        )
                        if appState.canUseBiometrics {
                            RowDivider()
                            biometricRow
                        }
                        RowDivider()
                        languageRow
                    }
                    .sideMargin()

                    SectionHeader("profile.section.firm")
                    RowCard {
                        if let invoice = appState.nextInvoice {
                            AppListRow(
                                title: Format.string("profile.fees"),
                                subtitle: Format.string("profile.fees.next \(Format.date(invoice.dueDate)) \(Format.money(invoice.amount))"),
                                systemImage: "creditcard",
                                isMonoSubtitle: true,
                                showsChevron: false
                            )
                            RowDivider()
                        }
                        Button {
                            if let url = appState.whatsAppURL(.general) { openURL(url) }
                        } label: {
                            AppListRow(
                                title: Format.string("profile.whatsapp"),
                                subtitle: "\(BrandConfiguration.current.contact.phone) · \(BrandConfiguration.current.contact.businessHours.resolved())",
                                systemImage: "bubble.left.and.text.bubble.right",
                                iconTone: .onTrack,
                                isMonoSubtitle: true
                            )
                        }
                        .buttonStyle(.plain)
                    }
                    .sideMargin()

                    SectionHeader("profile.section.privacy")
                    RowCard {
                        Button { showDeleteInfo = true } label: {
                            AppListRow(
                                title: Format.string("profile.deleteAccount"),
                                subtitle: Format.string("profile.deleteAccount.subtitle"),
                                systemImage: "trash"
                            )
                        }
                        .buttonStyle(.plain)
                        RowDivider()
                        Button { showSignOutConfirm = true } label: {
                            AppListRow(
                                title: Format.string("profile.signOut"),
                                systemImage: "rectangle.portrait.and.arrow.right",
                                iconTone: .critical,
                                showsChevron: false
                            )
                        }
                        .buttonStyle(.plain)
                    }
                    .sideMargin()

                    Text(verbatim: "\(BrandConfiguration.current.legalName) · v\(appVersion)")
                        .font(Theme.font(11.5))
                        .foregroundStyle(Theme.muted)
                        .frame(maxWidth: .infinity)
                        .padding(.top, 26)
                }
                .padding(.bottom, 28)
            }
            .background(Theme.background)
            .toolbar(.hidden, for: .navigationBar)
            .confirmationDialog(
                Text("profile.signOut.confirm"),
                isPresented: $showSignOutConfirm,
                titleVisibility: .visible
            ) {
                Button("profile.signOut", role: .destructive) { appState.signOut() }
                Button("common.cancel", role: .cancel) {}
            }
            .alert(Text("profile.deleteAccount"), isPresented: $showDeleteInfo) {
                Button("common.ok", role: .cancel) {}
                Button("profile.deleteAccount.request") {
                    if let url = appState.whatsAppURL(.general) { openURL(url) }
                }
            } message: {
                // Accounts are created by the firm, so deletion is a request —
                // and the app has to say plainly what the law obliges the firm to
                // keep, rather than promising an erasure it cannot perform.
                Text("profile.deleteAccount.explanation")
            }
        }
    }

    private var companyCard: some View {
        HStack(spacing: 14) {
            Text(appState.company?.initials ?? "")
                .font(Theme.font(17, weight: .semibold))
                .foregroundStyle(Theme.onBrand)
                .frame(width: 52, height: 52)
                .background(Theme.brass, in: Circle())

            VStack(alignment: .leading, spacing: 3) {
                Text(appState.company?.legalName ?? "")
                    .font(Theme.font(16.5, weight: .semibold))
                    .foregroundStyle(Theme.primary)
                    .fixedSize(horizontal: false, vertical: true)
                Text(Format.cnpj(appState.company?.cnpj ?? ""))
                    .font(Theme.mono(12.5))
                    .foregroundStyle(Theme.muted)
                Text("profile.signedInAs \(appState.company?.userEmail ?? "")")
                    .font(Theme.font(12))
                    .foregroundStyle(Theme.muted)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
        .card()
        .sideMargin()
    }

    private var biometricRow: some View {
        HStack(spacing: 13) {
            Image(systemName: "faceid")
                .font(.system(size: 17, weight: .medium))
                .foregroundStyle(Theme.primary)
                .frame(width: 38, height: 38)
                .background(Theme.fill, in: RoundedRectangle(cornerRadius: 10))

            Toggle(isOn: Binding(
                get: { appState.biometricEnabled },
                set: { appState.setBiometricEnabled($0) }
            )) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("profile.biometric \(appState.biometryName)")
                        .font(Theme.font(15, weight: .medium))
                        .foregroundStyle(Theme.primary)
                    Text("profile.biometric.footer \(appState.biometryName)")
                        .font(Theme.font(12.5))
                        .foregroundStyle(Theme.muted)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .tint(Theme.primary)
        }
        .padding(.horizontal, 15)
        .padding(.vertical, 12)
    }

    private var languageRow: some View {
        HStack(spacing: 13) {
            Image(systemName: "globe")
                .font(.system(size: 17, weight: .medium))
                .foregroundStyle(Theme.primary)
                .frame(width: 38, height: 38)
                .background(Theme.fill, in: RoundedRectangle(cornerRadius: 10))

            Picker(selection: Binding(
                get: { appState.language },
                set: { appState.language = $0 }
            )) {
                ForEach(AppLanguage.allCases) { language in
                    Text(language.labelKey).tag(language)
                }
            } label: {
                Text("profile.language")
                    .font(Theme.font(15, weight: .medium))
                    .foregroundStyle(Theme.primary)
            }
            .tint(Theme.primary)
        }
        .padding(.horizontal, 15)
        .padding(.vertical, 6)
        .frame(minHeight: Theme.minTouchTarget + 12)
    }

    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    }
}

#Preview {
    ProfileView().environment(AppState.signedInPreview())
}
