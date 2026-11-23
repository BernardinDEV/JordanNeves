import SwiftUI

/// Contato do escritório.
///
/// Quem abre esta aba já decidiu falar com alguém — a tela não tenta convencer
/// o cliente a resolver sozinho, e por isso não repete pendências nem prazos.
/// A ordem é deliberada: primeiro o que responde hoje, depois onde o escritório
/// fica, por último a presença pública.
///
/// Todo o conteúdo vem do `Brand.json` da marca. Nenhum dado de escritório é
/// escrito aqui: um escritório novo ganha esta tela preenchida sem tocar em
/// código — que é o teste de que a camada de marca cobre o que promete.
struct ContactView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.openURL) private var openURL

    private var brand: BrandConfiguration { .current }
    private var contact: BrandConfiguration.Contact { brand.contact }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    FirmCard(legalName: brand.legalName, tagline: brand.tagline.resolved())

                    SectionHeader("contact.section.talk")
                    RowCard {
                        Button(action: openWhatsApp) {
                            AppListRow(
                                title: Format.string("profile.whatsapp"),
                                subtitle: contact.businessHours.resolved(),
                                systemImage: "bubble.left.and.text.bubble.right",
                                iconTone: .onTrack
                            )
                        }
                        .buttonStyle(RowPressStyle())

                        ContactLinkRow(
                            title: Format.string("contact.phone"),
                            value: contact.phone,
                            systemImage: "phone",
                            url: URL(string: "tel:\(Self.dialable(contact.phone))"),
                            showsDivider: true
                        )
                        ContactLinkRow(
                            title: Format.string("contact.email"),
                            value: contact.email,
                            systemImage: "envelope",
                            url: URL(string: "mailto:\(contact.email)"),
                            showsDivider: true
                        )
                    }
                    .sideMargin()

                    SectionHeader("contact.section.office")
                    RowCard {
                        AppListRow(
                            title: Format.string("contact.address"),
                            subtitle: "\(contact.address) · \(contact.city)",
                            systemImage: "mappin.and.ellipse",
                            showsChevron: false
                        )
                        RowDivider()
                        AppListRow(
                            title: Format.string("contact.hours"),
                            subtitle: contact.businessHours.resolved(),
                            systemImage: "clock",
                            showsChevron: false
                        )
                    }
                    .sideMargin()

                    if hasOnlinePresence {
                        SectionHeader("contact.section.online")
                        RowCard {
                            ContactLinkRow(
                                title: Format.string("contact.website"),
                                value: Self.hostname(contact.website),
                                systemImage: "globe",
                                url: URL(string: contact.website),
                                showsDivider: false
                            )
                            if let instagram = contact.instagram {
                                ContactLinkRow(
                                    title: Format.string("contact.instagram"),
                                    value: Self.handle(instagram),
                                    systemImage: "camera",
                                    url: URL(string: instagram),
                                    showsDivider: true
                                )
                            }
                            if let linkedin = contact.linkedin {
                                ContactLinkRow(
                                    title: Format.string("contact.linkedin"),
                                    value: Self.handle(linkedin),
                                    systemImage: "briefcase",
                                    url: URL(string: linkedin),
                                    showsDivider: true
                                )
                            }
                        }
                        .sideMargin()
                    }

                    Text("contact.footnote")
                        .font(Theme.font(12.5))
                        .foregroundStyle(Theme.muted)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                        .sideMargin()
                        .padding(.top, 22)
                        .padding(.bottom, 28)
                }
            }
            .background(Theme.background)
            .navigationTitle(Text("contact.title"))
        }
    }

    private func openWhatsApp() {
        if let url = appState.whatsAppURL(.general) { openURL(url) }
    }

    private var hasOnlinePresence: Bool {
        !contact.website.isEmpty || contact.instagram != nil || contact.linkedin != nil
    }

    // MARK: - Formatting

    /// `tel:` só aceita dígitos e um `+` inicial.
    static func dialable(_ phone: String) -> String {
        let digits = phone.filter(\.isNumber)
        return phone.hasPrefix("+") ? "+\(digits)" : digits
    }

    /// `https://jordanneves.adv.br` → `jordanneves.adv.br`
    static func hostname(_ website: String) -> String {
        URL(string: website)?.host() ?? website
    }

    /// `https://instagram.com/jordannevesadv` → `@jordannevesadv`
    static func handle(_ profile: String) -> String {
        guard let last = URL(string: profile)?.pathComponents.last, last != "/" else {
            return hostname(profile)
        }
        return "@\(last)"
    }
}

#Preview {
    ContactView().environment(AppState.signedInPreview())
}
