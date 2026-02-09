import Foundation
import SwiftData

@Model
final class DailyChallenge {
    @Attribute(.unique) var dateKey: String // "yyyy-MM-dd"
    var reactionTimeMs: Int? // nil if false start (attempt used, no score)
    var attempted: Bool
    var timestamp: Date?

    init(dateKey: String) {
        self.dateKey = dateKey
        self.attempted = false
    }

    func recordResult(reactionTimeMs: Int?) {
        self.attempted = true
        self.reactionTimeMs = reactionTimeMs
        self.timestamp = Date()
    }

    var hasScore: Bool {
        reactionTimeMs != nil
    }
}
