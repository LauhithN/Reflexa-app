import Foundation

enum Formatters {
    static func reactionTime(_ ms: Int) -> String {
        "\(max(0, ms)) ms"
    }

    static func seconds(_ value: Double) -> String {
        String(format: "%.2fs", value)
    }

    static func stopwatchValue(_ value: Double) -> String {
        String(format: "%.3f", value)
    }

    static func stopwatchClock(_ value: Double) -> String {
        let totalMs = Int((max(0, value) * 1000).rounded())
        let minutes = totalMs / 60_000
        let seconds = (totalMs % 60_000) / 1000
        let millis = totalMs % 1000
        return String(format: "%02d:%02d.%03d", minutes, seconds, millis)
    }

    static func tapCount(_ count: Int) -> String {
        "\(max(0, count)) taps"
    }

    static func percentile(_ value: Int) -> String {
        "Top \(max(1, 100 - value))%"
    }

    static func displayDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}
