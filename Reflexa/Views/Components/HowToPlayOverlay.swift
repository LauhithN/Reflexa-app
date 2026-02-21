import SwiftUI

struct HowToPlayOverlay: View {
    let gameType: GameType
    let onDismiss: () -> Void

    private var instructions: [String] {
        switch gameType {
        case .stopwatch:
            return [
                "Start the timer and stop as close to 0.000 as possible.",
                "In multiplayer, each player takes one turn.",
                "Closest value to zero wins."
            ]
        case .colorFlash:
            return [
                "Watch the color transitions carefully.",
                "Tap only when the screen matches the target color.",
                "5 rounds score your color-match accuracy."
            ]
        case .quickTap:
            return [
                "Tap as fast as possible for 10 seconds.",
                "Every tap counts toward your total.",
                "Beat your personal best tap count."
            ]
        case .sequenceMemory:
            return [
                "Memorize the sequence glow pattern.",
                "Repeat it exactly to advance.",
                "One mistake ends the run."
            ]
        case .colorSort:
            return [
                "Read the word, but trust the ink color.",
                "Tap the matching ink color option.",
                "Fast and accurate answers win rounds."
            ]
        case .gridReaction:
            return [
                "Tap the lit cell as fast as possible.",
                "Multiplayer uses split zones and simultaneous rounds.",
                "Most round wins takes the game."
            ]
        case .reactionDuel:
            return [
                "Wait for the trigger flash.",
                "Tap your zone immediately after GO.",
                "Early taps add a false-start penalty."
            ]
        case .colorBattle:
            return [
                "Turn-based rounds with pass-device handoff.",
                "Match target colors to score points.",
                "Power-ups can swing the match."
            ]
        }
    }

    var body: some View {
        ZStack {
            Color.black.opacity(0.72).ignoresSafeArea()

            VStack(alignment: .leading, spacing: 14) {
                HStack(spacing: 10) {
                    Image(systemName: gameType.iconName)
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(Color.accentPrimary)
                    Text("How To Play")
                        .font(.resultTitle)
                        .foregroundStyle(Color.textPrimary)
                }

                Text(gameType.displayName)
                    .font(.sectionTitle)
                    .foregroundStyle(Color.textSecondary)

                ForEach(Array(instructions.enumerated()), id: \.offset) { _, line in
                    HStack(alignment: .top, spacing: 8) {
                        Circle()
                            .fill(Color.accentSecondary)
                            .frame(width: 6, height: 6)
                            .padding(.top, 6)
                        Text(line)
                            .font(.bodyLarge)
                            .foregroundStyle(Color.textPrimary)
                    }
                }

                Text("Tap anywhere to continue")
                    .font(.caption)
                    .foregroundStyle(Color.textTertiary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.top, 6)
            }
            .padding(20)
            .glassCard(cornerRadius: 22)
            .padding(.horizontal, 18)
        }
        .contentShape(Rectangle())
        .onTapGesture {
            onDismiss()
        }
    }
}

struct HowToPlayModifier: ViewModifier {
    let gameType: GameType

    @AppStorage private var hasSeenInstructions: Bool
    @State private var showOverlay: Bool

    init(gameType: GameType) {
        self.gameType = gameType
        let key = "hasSeenHowToPlay_\(gameType.rawValue)"
        _hasSeenInstructions = AppStorage(wrappedValue: false, key)
        _showOverlay = State(initialValue: !UserDefaults.standard.bool(forKey: key))
    }

    func body(content: Content) -> some View {
        ZStack {
            content

            if showOverlay {
                HowToPlayOverlay(gameType: gameType) {
                    showOverlay = false
                    hasSeenInstructions = true
                }
                .transition(.opacity)
            }
        }
    }
}

extension View {
    func howToPlayOverlay(for gameType: GameType) -> some View {
        modifier(HowToPlayModifier(gameType: gameType))
    }
}
