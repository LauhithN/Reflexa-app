import SwiftUI

struct PlayerResult: Identifiable {
    let id = UUID()
    let name: String
    let color: Color
    let score: Double
    let isWinner: Bool
    let isNewBest: Bool
    var rank: Int
}
