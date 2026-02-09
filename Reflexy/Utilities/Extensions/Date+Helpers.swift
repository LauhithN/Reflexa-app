import Foundation

extension Date {
    /// Returns date string in "yyyy-MM-dd" format for daily challenge keying
    var dailyKey: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter.string(from: self)
    }

    /// Seconds remaining until next midnight in local time
    var secondsUntilMidnight: TimeInterval {
        let calendar = Calendar.current
        guard let tomorrow = calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: self)) else {
            return 0
        }
        return tomorrow.timeIntervalSince(self)
    }

    /// Formatted countdown string "Xh Ym"
    var countdownToMidnight: String {
        let total = Int(secondsUntilMidnight)
        let hours = total / 3600
        let minutes = (total % 3600) / 60
        return "\(hours)h \(minutes)m"
    }
}
