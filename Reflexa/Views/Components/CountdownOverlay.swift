import SwiftUI

struct CountdownOverlay: View {
    let value: Int

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var scale: CGFloat = 0.6

    private var displayText: String {
        value > 0 ? "\(value)" : "GO!"
    }

    var body: some View {
        ZStack {
            AmbientBackground().overlay(Color.black.opacity(0.55))

            Text(displayText)
                .font(.monoLarge)
                .monospacedDigit()
                .foregroundStyle(value > 0 ? Color.textPrimary : Color.accentSecondary)
                .scaleEffect(scale)
                .onAppear {
                    playFeedback()
                    animate()
                }
                .onChange(of: value) { _ in
                    playFeedback()
                    animate()
                }
                .accessibilityLabel(value > 0 ? "Countdown \(value)" : "Go")
        }
    }

    private func playFeedback() {
        if value > 0 {
            HapticManager.shared.select()
        } else {
            HapticManager.shared.medium()
        }
    }

    private func animate() {
        guard !reduceMotion else {
            scale = 1
            return
        }

        scale = 0.6
        withAnimation(Spring.bouncy) {
            scale = 1
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
            withAnimation(Spring.snappy) {
                scale = 1.1
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.22) {
            withAnimation(Spring.instant) {
                scale = 1
            }
        }
    }
}
