import SwiftUI

enum Spring {
    static let snappy = Animation.spring(response: 0.25, dampingFraction: 0.82)
    static let bouncy = Animation.spring(response: 0.35, dampingFraction: 0.68)
    static let smooth = Animation.spring(response: 0.45, dampingFraction: 0.90)
    static let gentle = Animation.easeInOut(duration: 0.40)
    static let instant = Animation.spring(response: 0.18, dampingFraction: 0.90)
    static func linear(duration: Double) -> Animation {
        .linear(duration: duration)
    }

    static func easeOut(duration: Double) -> Animation {
        .easeOut(duration: duration)
    }

    static func ambient(duration: Double) -> Animation {
        .easeInOut(duration: duration)
    }

    static let stagger: (Int) -> Animation = { index in
        .spring(response: 0.40, dampingFraction: 0.84).delay(Double(index) * 0.04)
    }
}
