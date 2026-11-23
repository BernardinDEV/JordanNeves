import SwiftUI

/// A status badge. Always carries words — the app never encodes state in colour
/// alone, so it still reads for someone who can't tell amber from red.
struct StatePill: View {
    let text: String
    let tone: Tone

    enum Tone {
        case onTrack, attention, critical, neutral, brass

        var foreground: Color {
            switch self {
            case .onTrack: Theme.onTrack
            case .attention: Theme.attention
            case .critical: Theme.critical
            case .neutral: Theme.muted
            case .brass: Theme.brass
            }
        }

        var background: Color {
            switch self {
            case .neutral: Theme.fill
            default: foreground.opacity(0.14)
            }
        }
    }

    init(_ text: String, tone: Tone) {
        self.text = text
        self.tone = tone
    }

    init(state: CaseState) {
        self.text = Format.string(.init(state.labelKey))
        self.tone = switch state {
        case .requiresYou: .critical
        case .deadlineNear: .attention
        case .withCourt: .neutral
        case .onTrack: .onTrack
        }
    }

    var body: some View {
        Text(text)
            .font(Theme.font(11.5, weight: .semibold))
            .foregroundStyle(tone.foreground)
            .padding(.horizontal, 9)
            .padding(.vertical, 4)
            .background(tone.background, in: .rect(cornerRadius: Theme.Radius.pill))
            .fixedSize(horizontal: true, vertical: false)
            // O selo é um rótulo curto ao lado de um título: deixá-lo crescer
            // sem teto espreme o título até uma palavra por linha.
            .dynamicTypeSize(...DynamicTypeSize.accessibility1)
    }
}
