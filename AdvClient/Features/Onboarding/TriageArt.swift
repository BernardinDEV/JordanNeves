import SwiftUI

/// Ilustração da página 1: três cartões, só o que exige o cliente em destaque.
struct TriageArt: View {
    var body: some View {
        VStack(spacing: 11) {
            TriageArtCard(pill: "state.requiresYou", tone: .critical, title: "onb.art.case1", isDimmed: false)
            TriageArtCard(pill: "state.withCourt", tone: .neutral, title: "onb.art.case2", isDimmed: true)
            TriageArtCard(pill: "state.onTrack", tone: .onTrack, title: "onb.art.case3", isDimmed: true)
        }
        .padding(22)
    }
}
