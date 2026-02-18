import Foundation

enum Constants {
    // MARK: - Legal
    static let privacyPolicyURL = "https://lauhithn.github.io/reflexa-legal-pages/privacy.html"
    static let termsOfUseURL = "https://lauhithn.github.io/reflexa-legal-pages/terms.html"

    // MARK: - Timing
    static let countdownDuration: Int = 3
    static let minWaitTime: TimeInterval = 2.0
    static let maxWaitTime: TimeInterval = 5.0
    static let minSafeWaitTime: TimeInterval = 1.5 // Never trigger stimulus before this
    static let quickTapDuration: TimeInterval = 10.0
    static let gridReactionRounds: Int = 10
    static let stopwatchStartValue: Double = 100.0

    // MARK: - Sequence Memory
    static let sequenceMemoryFlashDuration: TimeInterval = 0.55
    static let sequenceMemoryFlashGap: TimeInterval = 0.18

    // MARK: - Color Sort
    static let colorSortDuration: TimeInterval = 15.0
    static let colorSortPenaltyFlashDuration: TimeInterval = 0.35

    // MARK: - Multiplayer
    static let colorBattle2PRounds: Int = 5
    static let colorBattle4PRounds: Int = 7

    // MARK: - Percentile Brackets (for reaction time in ms)
    static func percentile(forReactionMs ms: Int) -> Int {
        switch ms {
        case ..<150: return 99
        case 150..<180: return 97
        case 180..<200: return 93
        case 200..<220: return 88
        case 220..<250: return 80
        case 250..<280: return 70
        case 280..<320: return 55
        case 320..<400: return 35
        case 400..<500: return 15
        default: return 5
        }
    }

}
