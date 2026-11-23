import SwiftUI
import UIKit
import CoreText

/// Central design tokens.
///
/// Brand colours live in the asset catalog so each white-label target overrides
/// them without touching code. Semantic colours (on track / attention / critical)
/// stay here on purpose: green means "nothing pending" for every firm, and
/// letting a brand repaint it would break the meaning the whole app depends on.
enum Theme {

    // MARK: Brand (overridable per target)

    static let primary = Color("BrandPrimary")
    static let secondary = Color("BrandSecondary")
    static let muted = Color("BrandMuted")
    static let background = Color("BrandBackground")
    static let body = Color("BrandBody")
    static let line = Color("BrandLine")
    static let fill = Color("BrandFill")
    /// Rare accent — priority marks and section labels only.
    static let brass = Color("BrandBrass")

    /// Superfície de cartão. Era `.white` cravado em catorze lugares — o que
    /// impedia uma marca de fundo creme ou off-white e travaria o tema escuro
    /// no dia em que ele for desenhado.
    static let card = Color("BrandCard")

    /// Tinta sobre superfície da marca (`primary` ou `brass`). Não é branco
    /// fixo de propósito: marca de cor clara precisa de tinta escura aqui, e
    /// contraste é acessibilidade, não gosto.
    static let onBrand = Color("BrandOnBrand")

    // MARK: Semantic (fixed)

    static let onTrack = Color(red: 30 / 255, green: 122 / 255, blue: 92 / 255)
    static let attention = Color(red: 181 / 255, green: 114 / 255, blue: 26 / 255)
    static let critical = Color(red: 180 / 255, green: 52 / 255, blue: 46 / 255)

    static func color(for urgency: Urgency) -> Color {
        switch urgency {
        case .critical: critical
        case .warning: attention
        case .normal: onTrack
        }
    }

    static func color(for state: CaseState) -> Color {
        switch state {
        case .requiresYou: critical
        case .deadlineNear: attention
        case .withCourt: muted
        case .onTrack: onTrack
        }
    }

    // MARK: Layout

    /// Base grid. Spacings are multiples of 4; screens use a 20pt side margin.
    enum Space {
        static let side: CGFloat = 20
        static let card: CGFloat = 16
        static let tight: CGFloat = 8
        static let row: CGFloat = 12
    }

    enum Radius {
        static let card: CGFloat = 14
        static let sheet: CGFloat = 20
        static let control: CGFloat = 12
        static let pill: CGFloat = 7
    }

    /// Every tappable element is at least this tall — the audience is business
    /// owners in a hurry, often using the app standing up.
    static let minTouchTarget: CGFloat = 44

    // MARK: Typography (brand font with system fallback)

    /// Texto de interface no tamanho do protótipo, **acompanhando o Dynamic
    /// Type**. O tamanho pedido escolhe o estilo de texto do sistema mais
    /// próximo; quem aumenta a letra nos Ajustes vê o app inteiro crescer junto.
    ///
    /// Antes isto devolvia `.system(size:)`, que é tamanho fixo: o app ignorava
    /// a preferência de quem não enxerga letra de 13 pt.
    static func font(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        let style = textStyle(for: size)
        if brandFontAvailable {
            // Fonte da marca: mantém o tamanho exato e escala relativo ao estilo.
            return .custom(BrandConfiguration.current.fontFamily, size: size, relativeTo: style).weight(weight)
        }
        return .system(style, weight: weight)
    }

    /// Case numbers, money and dates. Tabular figures are not decoration here:
    /// a CNJ number is 20 digits and the client will compare it, character by
    /// character, against an e-mail from their accountant.
    static func mono(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        .system(textStyle(for: size), design: .monospaced, weight: weight)
    }

    /// O estilo de texto do sistema mais próximo de um tamanho do protótipo.
    static func textStyle(for size: CGFloat) -> Font.TextStyle {
        switch size {
        case ..<11.75: .caption2
        case ..<12.75: .caption
        case ..<13.75: .footnote
        case ..<15.75: .subheadline
        case ..<16.75: .callout
        case ..<18.5: .body
        case ..<21: .title3
        case ..<27: .title2
        case ..<31: .title
        default: .largeTitle
        }
    }

    /// Resolvido uma única vez. Era uma propriedade computada que fazia
    /// `UIFont(name:)` a **cada** chamada de `Theme.font` — centenas por
    /// atualização de tela, e a busca por uma fonte que não existe é a mais
    /// cara que o sistema de fontes faz.
    static let brandFontAvailable: Bool = {
        registerBundledFonts()
        return UIFont(name: BrandConfiguration.current.fontFamily, size: 12) != nil
    }()

    /// Registers every font bundled under Resources/Fonts at launch,
    /// so brands can ship fonts without Info.plist entries. Idempotent.
    static func registerBundledFonts() {
        _ = bundledFontsRegistration
    }

    private static let bundledFontsRegistration: Void = {
        for ext in ["ttf", "otf"] {
            for url in Bundle.main.urls(forResourcesWithExtension: ext, subdirectory: nil) ?? [] {
                CTFontManagerRegisterFontsForURL(url as CFURL, .process, nil)
            }
        }
    }()

    // MARK: Navigation bar

    /// Pinta os títulos da barra de navegação com a cor da marca. A barra é a
    /// do sistema — material, título grande que recolhe, gesto de voltar — e só
    /// a tinta muda. O SwiftUI ainda não expõe a cor do título, daí o UIKit.
    static func applyNavigationBarAppearance() {
        guard let color = UIColor(named: "BrandPrimary") else { return }
        let bar = UINavigationBar.appearance()
        bar.largeTitleTextAttributes = [.foregroundColor: color]
        bar.titleTextAttributes = [.foregroundColor: color]
    }
}
