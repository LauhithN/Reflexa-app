import SwiftUI
import SwiftData

struct DailyChallengeGameView: View {
    @State private var viewModel = DailyChallengeViewModel()
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        ZStack {
            backgroundView.ignoresSafeArea()

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
                        .foregroundStyle(Color.textPrimary)
                }

            case .falseStart:
                falseStartView

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

    @ViewBuilder
    private var backgroundView: some View {
        switch viewModel.state {
        case .active:
            RadialGradient(
                colors: [Color.accentHot.opacity(0.35), Color.appBackgroundSecondary, Color.appBackground],
                center: .center,
                startRadius: 20,
                endRadius: 420
            )

        case .falseStart:
            LinearGradient(
                colors: [Color.warning.opacity(0.4), Color.appBackground],
                startPoint: .top,
                endPoint: .bottom
            )

        default:
            AmbientBackground()
        }
    }

    private var falseStartView: some View {
        VStack(spacing: 16) {
            Text("FALSE START!")
                .font(.resultTitle)
                .foregroundStyle(Color.error)

            Text("Your daily attempt is used up")
                .font(.bodyLarge)
                .foregroundStyle(Color.textSecondary)

            Button("Back to Menu") {
                dismiss()
            }
            .buttonStyle(SecondaryCTAButtonStyle())
            .padding(.horizontal, 24)
            .accessibleTapTarget()
        }
        .padding(22)
        .glassCard(cornerRadius: 24)
        .padding(.horizontal, 16)
    }

    private var readyView: some View {
        VStack(spacing: 20) {
            Text("Daily Challenge")
                .font(.gameTitle)
                .foregroundStyle(Color.textPrimary)

            if viewModel.hasAttemptedToday {
                attemptedTodayView
            } else {
                availableTodayView
            }
        }
        .padding(22)
        .glassCard(cornerRadius: 24)
        .padding(.horizontal, 16)
    }

    private var attemptedTodayView: some View {
        VStack(spacing: 16) {
            if let score = viewModel.todayScore {
                Text("Today's Score")
                    .font(.bodyLarge)
                    .foregroundStyle(Color.textSecondary)

                Text(Formatters.reactionTime(score))
                    .font(.resultScore)
                    .monospacedDigit()
                    .foregroundStyle(Color.textPrimary)
            } else {
                Text("False start today")
                    .font(.bodyLarge)
                    .foregroundStyle(Color.error)
            }

            Text("Next challenge in \(viewModel.countdownToNext)")
                .font(.bodyLarge)
                .foregroundStyle(Color.textSecondary)

            if let best = viewModel.allTimeBest {
                StatBadge(label: "All-Time Best", value: Formatters.reactionTime(best))
            }

            Button("Back to Menu") {
                dismiss()
            }
            .buttonStyle(SecondaryCTAButtonStyle())
            .padding(.horizontal, 24)
            .accessibleTapTarget()
        }
    }

    private var availableTodayView: some View {
        VStack(spacing: 16) {
            Text("One shot. Make it count.")
                .font(.bodyLarge)
                .foregroundStyle(Color.textSecondary)

            if let best = viewModel.allTimeBest {
                StatBadge(label: "All-Time Best", value: Formatters.reactionTime(best))
            }

            Button("Start") {
                viewModel.startGame()
            }
            .buttonStyle(PrimaryCTAButtonStyle(tint: .accentPrimary))
            .padding(.horizontal, 24)
            .accessibleTapTarget()

            Button("Back") {
                dismiss()
            }
            .font(.caption)
            .foregroundStyle(Color.textSecondary)
            .accessibleTapTarget()
        }
    }

    private var resultView: some View {
        VStack(spacing: 20) {
            if let score = viewModel.todayScore {
                Text("Daily Challenge")
                    .font(.gameTitle)
                    .foregroundStyle(Color.textSecondary)

                Text(Formatters.reactionTime(score))
                    .font(.resultScore)
                    .monospacedDigit()
                    .foregroundStyle(Color.textPrimary)

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
                    .foregroundStyle(Color.textSecondary)
            }

            Text("Next challenge in \(viewModel.countdownToNext)")
                .font(.bodyLarge)
                .foregroundStyle(Color.textSecondary)

            Button("Menu") {
                dismiss()
            }
            .buttonStyle(SecondaryCTAButtonStyle())
            .padding(.horizontal, 24)
            .accessibleTapTarget()
        }
        .padding(22)
        .glassCard(cornerRadius: 24)
        .padding(.horizontal, 16)
    }
}
