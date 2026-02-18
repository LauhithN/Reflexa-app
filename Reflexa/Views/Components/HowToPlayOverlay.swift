import SwiftUI

/// Brief instruction overlay shown on first play of each game type.
struct HowToPlayOverlay: View {
    let gameType: GameType
    let onDismiss: () -> Void
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var instructions: String {
        switch gameType {
        case .stopwatch:
            return "A timer counts down from 100. Tap to stop it as close to 0 as possible. The closer you get, the better!"
        case .colorFlash:
            return "Stay calm during the wait. Decoy flashes may appear to trick you. Tap only when the REAL full red flash appears. Early taps are false starts."
        case .colorBattle:
            return "Battle over multiple rounds. First tap after signal scores points, and every 3rd round is a POWER round worth +2. False starts cost the faulter 1 point."
        case .reactionDuel:
            return "Wait for GO, then press and hold to charge power. Release as close as possible to the target zone. Lowest offset wins. Pressing early is a false start."
        case .dailyChallenge:
            return "You get one attempt per day. Wait for the color change and tap. Try to beat your all-time best!"
        case .quickTap:
            return "Tap the screen as many times as you can in 10 seconds. Every tap counts!"
        case .sequenceMemory:
            return "Watch the colored cells flash in sequence, then tap them back in the same order. Each level adds one more step. One wrong tap and it's game over!"
        case .colorSort:
            return "A color word appears in a different ink color. Tap the button matching the INK COLOR, not the word itself. Score as many as you can in 15 seconds!"
        case .gridReaction:
            return "A 4x4 grid of squares. When one lights up, tap it as fast as you can. 10 rounds — your score is the average time."
        }
    }

    var body: some View {
        ZStack {
            AmbientBackground()
                .overlay(Color.black.opacity(0.5))

            VStack(spacing: 24) {
                Image(systemName: gameType.iconName)
                    .font(.system(size: 48))
                    .foregroundStyle(Color.waiting)

                Text("How to Play")
                    .font(.gameTitle)
                    .foregroundStyle(Color.textPrimary)

                Text(gameType.displayName)
                    .font(.playerLabel)
                    .foregroundStyle(Color.waiting)

                Text(instructions)
                    .font(.bodyLarge)
                    .foregroundStyle(Color.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)

                Button {
                    onDismiss()
                } label: {
                    Text("Got it!")
                        .frame(minWidth: 200)
                }
                .buttonStyle(PrimaryCTAButtonStyle(tint: .accentPrimary))
                .accessibleTapTarget()
            }
            .padding(20)
            .glassCard(cornerRadius: 24)
            .padding(.horizontal, 18)
        }
        .transition(reduceMotion ? .opacity : .scale.combined(with: .opacity))
    }
}

/// Modifier that shows a how-to-play overlay on first play of each game type.
struct HowToPlayModifier: ViewModifier {
    let gameType: GameType
    @AppStorage private var hasSeenInstructions: Bool
    @State private var showOverlay: Bool
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    init(gameType: GameType) {
        self.gameType = gameType
        let key = "hasSeenHowToPlay_\(gameType.rawValue)"
        self._hasSeenInstructions = AppStorage(wrappedValue: false, key)
        self._showOverlay = State(initialValue: !UserDefaults.standard.bool(forKey: key))
    }

    func body(content: Content) -> some View {
        ZStack {
            content

            if showOverlay {
                HowToPlayOverlay(gameType: gameType) {
                    withAnimation(reduceMotion ? .linear(duration: 0.1) : .easeOut(duration: 0.3)) {
                        showOverlay = false
                    }
                    hasSeenInstructions = true
                }
            }
        }
    }
}

extension View {
    func howToPlayOverlay(for gameType: GameType) -> some View {
        modifier(HowToPlayModifier(gameType: gameType))
    }
}
