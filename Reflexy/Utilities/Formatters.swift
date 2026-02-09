import Foundation

enum Formatters {
    /// Format milliseconds for display: "234 ms"
    static func reactionTime(_ ms: Int) -> String {
        "\(ms) ms"
    }

    /// Format seconds with 2 decimal places: "1.23s"
    static func seconds(_ value: Double) -> String {
        String(format: "%.2fs", value)
    }

    /// Format stopwatch value with 2 decimal places: "45.67"
    static func stopwatchValue(_ value: Double) -> String {
        String(format: "%.2f", value)
    }

    /// Format tap count: "42 taps"
    static func tapCount(_ count: Int) -> String {
        "\(count) taps"
    }

    /// Format percentile: "Top 5%"
    static func percentile(_ value: Int) -> String {
        "Top \(100 - value)%"
    }

    /// Format date for display
    static func displayDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}
