import Foundation
import QuartzCore

/// High-precision gameplay timing built on CADisplayLink.
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

    private(set) var elapsed: CFTimeInterval = 0

    func start(onTick: @escaping (CFTimeInterval) -> Void) {
        stop()
        self.onTick = onTick
        startTime = CACurrentMediaTime()
        pausedAt = nil
        pausedDuration = 0
        elapsed = 0

        let proxy = DisplayLinkProxy(owner: self)
        let link = CADisplayLink(target: proxy, selector: #selector(DisplayLinkProxy.tick))
        link.add(to: .main, forMode: .common)
        displayLink = link
        displayLinkProxy = proxy
    }

    func stop() {
        displayLink?.invalidate()
        displayLink = nil
        displayLinkProxy = nil
        onTick = nil
        isPaused = false
        pausedAt = nil
        pausedDuration = 0
        elapsed = 0
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

    static func now() -> CFTimeInterval {
        CACurrentMediaTime()
    }

    static func reactionMs(from start: CFTimeInterval, to end: CFTimeInterval) -> Int {
        max(0, Int((end - start) * 1000))
    }

    deinit {
        displayLink?.invalidate()
    }
}
