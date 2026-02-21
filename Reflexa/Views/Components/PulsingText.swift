import SwiftUI

struct PulsingText: View {
    let text: String
    let color: Color

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var pulsing = false

    var body: some View {
        Text(text)
            .font(.resultTitle)
            .foregroundStyle(color)
            .opacity(reduceMotion ? 1 : (pulsing ? 0.45 : 1))
            .onAppear {
                guard !reduceMotion else { return }
                withAnimation(Spring.gentle.repeatForever(autoreverses: true)) {
                    pulsing = true
                }
            }
    }
}
