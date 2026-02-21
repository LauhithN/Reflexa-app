import Foundation

final class HapticService {
    static let shared = HapticService()

    private init() {}

    func lightTap() {
        HapticManager.shared.light()
    }

    func countdownBeat() {
        HapticManager.shared.select()
    }

    func goImpact() {
        HapticManager.shared.medium()
    }

    func success() {
        HapticManager.shared.success()
    }

    func error() {
        HapticManager.shared.error()
    }

    func warning() {
        HapticManager.shared.warning()
    }

    func vibrationStimulus() {
        HapticManager.shared.heavy()
    }
}
