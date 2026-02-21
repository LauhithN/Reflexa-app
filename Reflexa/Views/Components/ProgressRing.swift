import SwiftUI

struct ProgressRing: View {
    var progress: Double
    var color: Color = .accentPrimary
    var lineWidth: CGFloat = 8

    private var clampedProgress: Double {
        min(max(progress, 0), 1)
    }

    var body: some View {
        Circle()
            .trim(from: 0, to: clampedProgress)
            .stroke(
                color,
                style: StrokeStyle(lineWidth: lineWidth, lineCap: .round, lineJoin: .round)
            )
            .rotationEffect(.degrees(-90))
            .animation(Spring.smooth, value: clampedProgress)
    }
}
