import SwiftUI
import SwiftData

struct DailyChallengeGameView: View {
    @State private var viewModel = DailyChallengeViewModel()
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        ZStack {
            backgroundColor.ignoresSafeArea()

            switch viewModel.state {
            case .ready:
                readyView

            case .countdown(let value):
                CountdownOverlay(value: value)

            case .waiting:
                PulsingText(text: "Wait...", color: .waiting)

            case .active:
                VStack {
                    Text("TAP NOW!")
                        .font(.resultTitle)
                        .foregroundStyle(.white)
                }

            case .falseStart:
                VStack(spacing: 16) {
                    Text("FALSE START!")
                        .font(.resultTitle)
                        .foregroundStyle(Color.error)
                    Text("Your daily attempt is used up")
                        .font(.bodyLarge)
                        .foregroundStyle(.gray)
                }

            case .result:
                resultView

            default:
                EmptyView()
            }
        }
        .overlay {
            if viewModel.state == .waiting || viewModel.state == .active {
                Color.clear
                    .contentShape(Rectangle())
                    .onTapGesture {
                        viewModel.playerTapped(index: 0)
                    }
            }
        }
        .onAppear {
            viewModel.loadStatus(modelContext: modelContext)
        }
        .navigationBarHidden(true)
        .statusBarHidden()
    }

    private var backgroundColor: Color {
        switch viewModel.state {
        case .active: return .red
        case .falseStart: return Color.warning.opacity(0.3)
        default: return .appBackground
        }
    }

    private var readyView: some View {
        VStack(spacing: 24) {
            Text("Daily Challenge")
                .font(.gameTitle)
                .foregroundStyle(.white)

            if viewModel.hasAttemptedToday {
                if let score = viewModel.todayScore {
                    Text("Today's Score")
                        .font(.bodyLarge)
                        .foregroundStyle(.gray)
                    Text(Formatters.reactionTime(score))
                        .font(.resultScore)
                        .monospacedDigit()
                        .foregroundStyle(.white)
                } else {
                    Text("False start today")
                        .font(.bodyLarge)
                        .foregroundStyle(Color.error)
                }

                Text("Next challenge in \(viewModel.countdownToNext)")
                    .font(.bodyLarge)
                    .foregroundStyle(.gray)

                if let best = viewModel.allTimeBest {
                    StatBadge(label: "All-Time Best", value: Formatters.reactionTime(best))
                }

                Button("Back to Menu") {
                    dismiss()
                }
                .font(.bodyLarge)
                .foregroundStyle(.gray)
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(Color.cardBackground)
                .clipShape(Capsule())
                .accessibleTapTarget()
            } else {
                Text("One shot. Make it count.")
                    .font(.bodyLarge)
                    .foregroundStyle(.gray)

                if let best = viewModel.allTimeBest {
                    StatBadge(label: "All-Time Best", value: Formatters.reactionTime(best))
                }

                Button("Start") {
                    viewModel.startGame()
                }
                .font(.bodyLarge)
                .foregroundStyle(.white)
                .padding(.horizontal, 48)
                .padding(.vertical, 16)
                .background(Color.waiting)
                .clipShape(Capsule())
                .accessibleTapTarget()

                Button("Back") {
                    dismiss()
                }
                .font(.caption)
                .foregroundStyle(.gray)
                .accessibleTapTarget()
            }
        }
    }

    private var resultView: some View {
        VStack(spacing: 24) {
            if let score = viewModel.todayScore {
                Text("Daily Challenge")
                    .font(.gameTitle)
                    .foregroundStyle(.gray)

                Text(Formatters.reactionTime(score))
                    .font(.resultScore)
                    .monospacedDigit()
                    .foregroundStyle(.white)

                PercentileBar(percentile: viewModel.percentile)
                    .padding(.horizontal, 40)

                if let best = viewModel.allTimeBest {
                    StatBadge(label: "All-Time Best", value: Formatters.reactionTime(best))
                }
            } else {
                Text("False Start")
                    .font(.resultTitle)
                    .foregroundStyle(Color.error)
                Text("Better luck tomorrow!")
                    .font(.bodyLarge)
                    .foregroundStyle(.gray)
            }

            Text("Next challenge in \(viewModel.countdownToNext)")
                .font(.bodyLarge)
                .foregroundStyle(.gray)

            Button("Menu") {
                dismiss()
            }
            .font(.bodyLarge)
            .foregroundStyle(.gray)
            .padding(.horizontal, 24)
            .padding(.vertical, 12)
            .background(Color.cardBackground)
            .clipShape(Capsule())
            .accessibleTapTarget()
        }
    }
}
