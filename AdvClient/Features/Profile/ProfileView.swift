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
                VStack(spacing: 0) {
                    if let company = appState.company {
                        CompanyCard(company: company)
                    }

                    SectionHeader("profile.section.account")
                    RowCard {
                        // Informativas: sem chevron, porque não levam a lugar nenhum.
                        // Pessoa física não tem "usuários da empresa".
                        if !appState.isPersonalAccount {
                            AppListRow(
                                title: Format.string("profile.users"),
                                subtitle: Format.string("profile.users.count \(3)"),
                                systemImage: "person.2",
                                showsChevron: false
                            )
                            RowDivider()
                        }
                        AppListRow(
                            title: Format.string("profile.notifications"),
                            subtitle: Format.string("profile.notifications.value"),
                            systemImage: "bell",
                            showsChevron: false
                        )
                        if appState.canUseBiometrics {
                            RowDivider()
                            BiometricToggleRow()
                        }
                        RowDivider()
                        LanguagePickerRow()
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
                        Button(action: openWhatsApp) {
                            AppListRow(
                                title: Format.string("profile.whatsapp"),
                                subtitle: "\(BrandConfiguration.current.contact.phone) · \(BrandConfiguration.current.contact.businessHours.resolved())",
                                systemImage: "bubble.left.and.text.bubble.right",
                                iconTone: .onTrack,
                                isMonoSubtitle: true
                            )
                        }
                        .buttonStyle(RowPressStyle())
                    }
                    .sideMargin()

                    SectionHeader("profile.section.privacy")
                    RowCard {
                        Button(action: askAboutDeletion) {
                            AppListRow(
                                title: Format.string("profile.deleteAccount"),
                                subtitle: Format.string("profile.deleteAccount.subtitle"),
                                systemImage: "trash"
                            )
                        }
                        .buttonStyle(RowPressStyle())
                        RowDivider()
                        Button(action: askToSignOut) {
                            AppListRow(
                                title: Format.string("profile.signOut"),
                                systemImage: "rectangle.portrait.and.arrow.right",
                                iconTone: .critical,
                                showsChevron: false
                            )
                        }
                        .buttonStyle(RowPressStyle())
                        // Preso ao botão que o abre, para o diálogo nascer dele.
                        .confirmationDialog(
                            Text("profile.signOut.confirm"),
                            isPresented: $showSignOutConfirm,
                            titleVisibility: .visible
                        ) {
                            Button("profile.signOut", role: .destructive, action: signOut)
                            Button("common.cancel", role: .cancel) {}
                        }
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
            .navigationTitle(Text("profile.title"))
            .alert(Text("profile.deleteAccount"), isPresented: $showDeleteInfo) {
                Button("common.ok", role: .cancel) {}
                Button("profile.deleteAccount.request", action: openWhatsApp)
            } message: {
                // Accounts are created by the firm, so deletion is a request —
                // and the app has to say plainly what the law obliges the firm to
                // keep, rather than promising an erasure it cannot perform.
                Text("profile.deleteAccount.explanation")
            }
        }
    }

    private func openWhatsApp() {
        if let url = appState.whatsAppURL(.general) { openURL(url) }
    }

    private func askAboutDeletion() {
        showDeleteInfo = true
    }

    private func askToSignOut() {
        showSignOutConfirm = true
    }

    private func signOut() {
        appState.signOut()
    }

    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    }
}

#Preview {
    ProfileView().environment(AppState.signedInPreview())
}
