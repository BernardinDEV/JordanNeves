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
                LazyVStack(spacing: 0) {
                    Text("contact.title")
                        .font(Theme.font(34, weight: .bold))
                        .foregroundStyle(Theme.primary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .sideMargin()
                        .padding(.top, 14)
                        .padding(.bottom, 16)

                    firmCard

                    SectionHeader("contact.section.talk")
                    RowCard {
                        Button {
                            if let url = appState.whatsAppURL(.general) { openURL(url) }
                        } label: {
                            AppListRow(
                                title: Format.string("profile.whatsapp"),
                                subtitle: contact.businessHours.resolved(),
                                systemImage: "bubble.left.and.text.bubble.right",
                                iconTone: .onTrack
                            )
                        }
                        .buttonStyle(.plain)

                        RowDivider()
                        link(
                            titleKey: "contact.phone",
                            value: contact.phone,
                            systemImage: "phone",
                            url: URL(string: "tel:\(Self.dialable(contact.phone))")
                        )

                        RowDivider()
                        link(
                            titleKey: "contact.email",
                            value: contact.email,
                            systemImage: "envelope",
                            url: URL(string: "mailto:\(contact.email)")
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
                            link(
                                titleKey: "contact.website",
                                value: Self.hostname(contact.website),
                                systemImage: "globe",
                                url: URL(string: contact.website)
                            )
                            if let instagram = contact.instagram {
                                RowDivider()
                                link(
                                    titleKey: "contact.instagram",
                                    value: Self.handle(instagram),
                                    systemImage: "camera",
                                    url: URL(string: instagram)
                                )
                            }
                            if let linkedin = contact.linkedin {
                                RowDivider()
                                link(
                                    titleKey: "contact.linkedin",
                                    value: Self.handle(linkedin),
                                    systemImage: "briefcase",
                                    url: URL(string: linkedin)
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
            .background(Theme.background.ignoresSafeArea())
            .navigationBarHidden(true)
        }
    }

    // MARK: - Pieces

    private var firmCard: some View {
        HStack(spacing: 14) {
            BrandMark()
                .frame(width: 46, height: 46)

            VStack(alignment: .leading, spacing: 3) {
                Text(verbatim: brand.legalName)
                    .font(Theme.font(16.5, weight: .semibold))
                    .foregroundStyle(Theme.primary)
                    .fixedSize(horizontal: false, vertical: true)
                Text(verbatim: brand.tagline.resolved())
                    .font(Theme.font(13))
                    .foregroundStyle(Theme.muted)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
        .card()
        .sideMargin()
    }

    /// Uma linha que abre algo fora do app. Some quando a URL não se forma —
    /// linha morta em tela de contato é pior do que ausência.
    @ViewBuilder
    private func link(
        titleKey: String.LocalizationValue,
        value: String,
        systemImage: String,
        url: URL?
    ) -> some View {
        if let url {
            Button { openURL(url) } label: {
                AppListRow(
                    title: Format.string(titleKey),
                    subtitle: value,
                    systemImage: systemImage,
                    isMonoSubtitle: true
                )
            }
            .buttonStyle(.plain)
        }
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
