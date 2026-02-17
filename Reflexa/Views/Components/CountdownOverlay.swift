import SwiftUI

/// Full-screen countdown overlay: 3... 2... 1... GO!
struct CountdownOverlay: View {
    let value: Int
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ZStack {
            AmbientBackground()
                .overlay(Color.black.opacity(0.45))

            Text(value > 0 ? "\(value)" : "GO!")
                .font(.countdownNumber)
                .monospacedDigit()
                .foregroundStyle(value > 0 ? Color.textPrimary : Color.success)
                .shadow(color: .black.opacity(0.25), radius: 12, y: 8)
                .if(!reduceMotion) { view in
                    view.contentTransition(.numericText())
                }
                .accessibilityLabel(value > 0 ? "Countdown \(value)" : "Go")
        }
    }
}
