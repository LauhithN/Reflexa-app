import SwiftUI
import UIKit

final class HapticManager {
    static let shared = HapticManager()

    @AppStorage("hapticsEnabled")
    private var hapticsEnabled = true

    private init() {}

    private func perform(_ action: () -> Void) {
        guard hapticsEnabled else { return }
        action()
    }

    func light() {
        perform {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        }
    }

    func medium() {
        perform {
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        }
    }

    func heavy() {
        perform {
            UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
        }
    }

    func success() {
        perform {
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        }
    }

    func error() {
        perform {
            UINotificationFeedbackGenerator().notificationOccurred(.error)
        }
    }

    func warning() {
        perform {
            UINotificationFeedbackGenerator().notificationOccurred(.warning)
        }
    }

    func select() {
        perform {
            UISelectionFeedbackGenerator().selectionChanged()
        }
    }

    func doublePulse() {
        success()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            self?.success()
        }
    }
}
