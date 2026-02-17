import SwiftUI

/// Text that pulses opacity — used for "Wait..." and "Get Ready" states
struct PulsingText: View {
    let text: String
    let color: Color
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isPulsing = false

    var body: some View {
        Text(text)
            .font(.gameTitle)
            .foregroundStyle(color)
            .opacity(reduceMotion ? 1.0 : (isPulsing ? 0.4 : 1.0))
            .onAppear {
                guard !reduceMotion else { return }
                withAnimation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true)) {
                    isPulsing = true
                }
            }
            .accessibilityLabel(text)
    }
}
