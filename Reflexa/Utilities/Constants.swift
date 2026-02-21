import Foundation

enum Constants {
    static let privacyPolicyURL = "https://lauhithn.github.io/reflexa-legal-pages/privacy.html"
    static let termsOfUseURL = "https://lauhithn.github.io/reflexa-legal-pages/terms.html"
    static let supportURL = "https://lauhithn.github.io/reflexa-legal-pages/support.html"

    static let countdownDuration: Int = 3
    static let quickTapDuration: TimeInterval = 10
    static let colorSortRoundDuration: TimeInterval = 5
    static let colorSortDuration: TimeInterval = 15
    static let colorSortPenaltyFlashDuration: TimeInterval = 0.35
    static let gridReactionRounds: Int = 10
    static let reactionDuelRounds: Int = 5
    static let colorBattle2PRounds: Int = 7
    static let colorBattle4PRounds: Int = 10
    static let stopwatchStartValue: Double = 0

    static let minWaitTime: TimeInterval = 1.5
    static let maxWaitTime: TimeInterval = 5.0
    static let minSafeWaitTime: TimeInterval = 1.5

    static let sequenceMemoryFlashDuration: TimeInterval = 0.5
    static let sequenceMemoryFlashGap: TimeInterval = 0.2

    static func percentile(forReactionMs ms: Int) -> Int {
        switch ms {
        case ..<160: return 95
        case 160..<190: return 90
        case 190..<220: return 82
        case 220..<250: return 72
        case 250..<290: return 58
        case 290..<340: return 42
        case 340..<420: return 25
        default: return 10
        }
    }
}
