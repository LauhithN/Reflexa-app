import UIKit

/// Service for sharing game results
enum ShareService {
    static func shareResult(gameType: GameType, score: String, percentile: Int?) {
        let presentShareSheet = {
            var text = "Reflexa - \(gameType.displayName)\nScore: \(score)"
            if let percentile {
                text += "\n\(Formatters.percentile(percentile))"
            }
            text += "\n\nCan you beat my score?"

            let activityVC = UIActivityViewController(
                activityItems: [text],
                applicationActivities: nil
            )

            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let rootVC = windowScene.windows.first?.rootViewController {
                // Handle iPad popover
                if let popover = activityVC.popoverPresentationController {
                    popover.sourceView = rootVC.view
                    popover.sourceRect = CGRect(x: rootVC.view.bounds.midX, y: rootVC.view.bounds.midY, width: 0, height: 0)
                    popover.permittedArrowDirections = []
                }
                rootVC.present(activityVC, animated: true)
            }
        }

        if Thread.isMainThread {
            presentShareSheet()
        } else {
            DispatchQueue.main.async(execute: presentShareSheet)
        }
    }
}
