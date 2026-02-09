import SwiftUI

/// Full-screen countdown overlay: 3... 2... 1... GO!
struct CountdownOverlay: View {
    let value: Int

    var body: some View {
        ZStack {
            Color.appBackground.opacity(0.9)
                .ignoresSafeArea()

            Text(value > 0 ? "\(value)" : "GO!")
                .font(.countdownNumber)
                .monospacedDigit()
                .foregroundStyle(value > 0 ? .white : Color.success)
                .contentTransition(.numericText())
                .accessibilityLabel(value > 0 ? "Countdown \(value)" : "Go")
        }
    }
}
