import SwiftUI

struct ContactView: View {
    private let brand = BrandConfiguration.current
    @Environment(\.openURL) private var openURL

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    VStack(spacing: 8) {
                        Image("LogoVertical")
                            .resizable()
                            .scaledToFit()
                            .frame(maxWidth: 160)
                        Text("contact.subtitle")
                            .font(Theme.font(14))
                            .foregroundStyle(Theme.muted)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, 8)

                    VStack(spacing: 12) {
                        ContactRow(icon: "phone.fill", titleKey: "contact.phone", value: brand.contact.phone) {
                            call(brand.contact.phone)
                        }
                        ContactRow(icon: "message.fill", titleKey: "contact.whatsapp", value: brand.contact.whatsapp) {
                            whatsapp(brand.contact.whatsapp)
                        }
                        ContactRow(icon: "envelope.fill", titleKey: "contact.email", value: brand.contact.email) {
                            openURL(URL(string: "mailto:\(brand.contact.email)")!)
                        }
                        ContactRow(icon: "globe", titleKey: "contact.website", value: brand.contact.website
                            .replacingOccurrences(of: "https://", with: "")) {
                            openURL(URL(string: brand.contact.website)!)
                        }
                    }

                    VStack(alignment: .leading, spacing: 12) {
                        Text("contact.section.office")
                            .font(Theme.font(13, weight: .semibold))
                            .foregroundStyle(Theme.muted)
                            .textCase(.uppercase)
                        InfoRow(labelKey: "contact.address", value: "\(brand.contact.address)\n\(brand.contact.city)")
                        Divider()
                        InfoRow(labelKey: "contact.hours", value: String(localized: String.LocalizationValue(brand.contact.businessHours)))
                        Button {
                            openMaps()
                        } label: {
                            Label("contact.openInMaps", systemImage: "map.fill")
                                .font(Theme.font(14, weight: .semibold))
                        }
                        .padding(.top, 2)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .card()

                    HStack(spacing: 14) {
                        SocialButton(label: "Instagram", systemImage: "camera.fill", url: brand.contact.instagram)
                        SocialButton(label: "LinkedIn", systemImage: "link", url: brand.contact.linkedin)
                    }
                }
                .padding(20)
            }
            .background(Theme.background)
            .navigationTitle("contact.title")
        }
    }

    private func call(_ phone: String) {
        let digits = phone.filter { $0.isNumber || $0 == "+" }
        if let url = URL(string: "tel:\(digits)") { openURL(url) }
    }

    private func whatsapp(_ phone: String) {
        let digits = phone.filter(\.isNumber)
        if let url = URL(string: "https://wa.me/\(digits)") { openURL(url) }
    }

    private func openMaps() {
        let query = "\(brand.contact.address), \(brand.contact.city)"
            .addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        if let url = URL(string: "https://maps.apple.com/?q=\(query)") { openURL(url) }
    }
}

private struct ContactRow: View {
    let icon: String
    let titleKey: LocalizedStringKey
    let value: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundStyle(.white)
                    .frame(width: 38, height: 38)
                    .background(Theme.primary)
                    .clipShape(RoundedRectangle(cornerRadius: 10))

                VStack(alignment: .leading, spacing: 2) {
                    Text(titleKey)
                        .font(Theme.font(12, weight: .medium))
                        .foregroundStyle(Theme.muted)
                    Text(value)
                        .font(Theme.font(15, weight: .semibold))
                        .foregroundStyle(Theme.primary)
                }

                Spacer()

                Image(systemName: "arrow.up.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Theme.secondary)
            }
            .card()
        }
        .buttonStyle(.plain)
    }
}

private struct SocialButton: View {
    let label: String
    let systemImage: String
    let url: String
    @Environment(\.openURL) private var openURL

    var body: some View {
        Button {
            if let url = URL(string: url) { openURL(url) }
        } label: {
            Label(label, systemImage: systemImage)
                .font(Theme.font(14, weight: .semibold))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(Theme.primary.opacity(0.08))
                .foregroundStyle(Theme.primary)
                .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }
}

#Preview {
    ContactView()
}
