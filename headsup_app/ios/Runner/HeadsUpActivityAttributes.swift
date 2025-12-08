import ActivityKit
import Foundation

// Define the attributes for the Live Activity
// This file is shared between the main app (Runner) and the Widget Extension
@available(iOS 16.1, *)
struct HeadsUpActivityAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        var sessionId: String
        var elapsedSeconds: Int
        var currentState: String  // "excellent", "good", "okay", "bad", "poor"
        var totalPoints: Int
        var pointsPerMinute: Int
        var angle: Double
        var isPaused: Bool
    }
    
    var startTime: Date
}
