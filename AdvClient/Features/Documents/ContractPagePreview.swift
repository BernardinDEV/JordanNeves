import SwiftUI

/// Stand-in for the PDF page. The real build renders the first page with
/// PDFKit from a signed, short-lived URL.
struct ContractPagePreview: View {
    let title: String

    var body: some View {
        VStack(spacing: 9) {
            VStack(alignment: .leading, spacing: 7) {
                Text(title.uppercased())
                    .font(.system(size: 8, weight: .bold))
                    .foregroundStyle(Theme.primary)
                    .lineLimit(2)
                    .padding(.bottom, 6)
                ForEach(0..<7, id: \.self) { index in
                    Capsule()
                        .fill(Theme.line)
                        .frame(maxWidth: index % 3 == 2 ? 62 : .infinity, alignment: .leading)
                        .frame(height: 3)
                }
                Spacer(minLength: 0)
            }
            .padding(14)
            .frame(width: 172, height: 214, alignment: .topLeading)
            .background(Theme.card, in: .rect(cornerRadius: 5))
            .shadow(color: Theme.primary.opacity(0.16), radius: 6, y: 3)

            Text("docs.pageOf \(1) \(14)")
                .font(Theme.mono(11))
                .foregroundStyle(Theme.muted)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .background(Theme.fill, in: .rect(cornerRadius: Theme.Radius.card))
        // É uma miniatura ilustrativa: o título vem logo abaixo, em texto.
        .accessibilityHidden(true)
    }
}
