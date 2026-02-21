import Foundation
import QuartzCore
import UIKit

/// High-precision timing using CADisplayLink for gameplay timers.
/// NEVER use Timer for gameplay — CADisplayLink syncs with display refresh for smooth updates.
@Observable
final class TimingService {
    private final class DisplayLinkProxy {
        weak var owner: TimingService?

        init(owner: TimingService) {
            self.owner = owner
        }

        @objc func tick() {
            owner?.tick()
        }
    }

    private var displayLink: CADisplayLink?
    private var displayLinkProxy: DisplayLinkProxy?
    private var startTime: CFTimeInterval = 0
    private var pausedAt: CFTimeInterval?
    private var pausedDuration: CFTimeInterval = 0
    private var onTick: ((CFTimeInterval) -> Void)?
    private var isPaused = false

    /// Current elapsed time since start, in seconds
    private(set) var elapsed: CFTimeInterval = 0

    /// Start the display link timer with a tick callback
    func start(onTick: @escaping (CFTimeInterval) -> Void) {
        stop()
        self.onTick = onTick
        self.startTime = CACurrentMediaTime()
        self.pausedAt = nil
        self.pausedDuration = 0
        self.elapsed = 0

        let proxy = DisplayLinkProxy(owner: self)
        let link = CADisplayLink(target: proxy, selector: #selector(DisplayLinkProxy.tick))
        link.add(to: .main, forMode: .common)
        self.displayLink = link
        self.displayLinkProxy = proxy
    }

    /// Stop and clean up the display link
    func stop() {
        displayLink?.invalidate()
        displayLink = nil
        displayLinkProxy = nil
        onTick = nil
        isPaused = false
        pausedAt = nil
        pausedDuration = 0
    }

    func pause() {
        guard !isPaused else { return }
        pausedAt = CACurrentMediaTime()
        displayLink?.isPaused = true
        isPaused = true
    }

    func resume() {
        guard isPaused else { return }
        if let pausedAt {
            pausedDuration += CACurrentMediaTime() - pausedAt
        }
        self.pausedAt = nil
        displayLink?.isPaused = false
        isPaused = false
    }

    @objc private func tick() {
        elapsed = CACurrentMediaTime() - startTime - pausedDuration
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
