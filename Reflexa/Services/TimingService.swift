import Foundation
import QuartzCore
import UIKit

/// High-precision timing using CADisplayLink for gameplay timers.
/// NEVER use Timer for gameplay — CADisplayLink syncs with display refresh for smooth updates.
@Observable
final class TimingService {
    private var displayLink: CADisplayLink?
    private var startTime: CFTimeInterval = 0
    private var onTick: ((CFTimeInterval) -> Void)?
    private var isPaused = false

    /// Current elapsed time since start, in seconds
    private(set) var elapsed: CFTimeInterval = 0

    /// Start the display link timer with a tick callback
    func start(onTick: @escaping (CFTimeInterval) -> Void) {
        stop()
        self.onTick = onTick
        self.startTime = CACurrentMediaTime()
        self.elapsed = 0

        let link = CADisplayLink(target: self, selector: #selector(tick))
        link.add(to: .main, forMode: .common)
        self.displayLink = link
    }

    /// Stop and clean up the display link
    func stop() {
        displayLink?.invalidate()
        displayLink = nil
        onTick = nil
    }

    func pause() {
        displayLink?.isPaused = true
        isPaused = true
    }

    func resume() {
        displayLink?.isPaused = false
        isPaused = false
    }

    @objc private func tick() {
        elapsed = CACurrentMediaTime() - startTime
        onTick?(elapsed)
    }

    /// Capture a precise timestamp (use for reaction time measurement)
    static func now() -> CFTimeInterval {
        CACurrentMediaTime()
    }

    /// Calculate reaction time in milliseconds between two CACurrentMediaTime timestamps
    static func reactionMs(from start: CFTimeInterval, to end: CFTimeInterval) -> Int {
        Int((end - start) * 1000)
    }

    deinit {
        stop()
    }
}
