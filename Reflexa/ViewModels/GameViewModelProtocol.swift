import Foundation

/// Common game states used by all game view models
enum GameState: Equatable {
    case ready
    case countdown(Int) // 3, 2, 1
    case waiting       // Waiting for stimulus (random delay)
    case active        // Game is active (stimulus shown, timer running)
    case stopped       // Player stopped/tapped
    case falseStart(Int?) // Player index who false-started (nil for solo)
    case result
}

/// Protocol that all game ViewModels conform to
protocol GameViewModelProtocol: AnyObject {
    var state: GameState { get }
    var config: GameConfiguration { get }

    func startGame()
    func resetGame()
    func playerTapped(index: Int)
}
