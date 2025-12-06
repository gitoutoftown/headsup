import ActivityKit
import SwiftUI

// Define the attributes for the Live Activity
struct PostureActivityAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        var sessionId: String
        var elapsedSeconds: Int
        var currentState: String  // "excellent", "good", "okay", "bad", "poor"
        var totalPoints: Int
        var pointsPerMinute: Int
        var angle: Double
    }
    
    var startTime: Date
}

// Live Activity widget for Dynamic Island
@available(iOS 16.1, *)
struct PostureLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: PostureActivityAttributes.self) { context in
            // Lock screen / banner UI
            PostureLockScreenView(context: context)
        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded view (long press)
                DynamicIslandExpandedRegion(.leading) {
                    PostureStateIcon(state: context.state.currentState)
                }
                
                DynamicIslandExpandedRegion(.trailing) {
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("+\(context.state.totalPoints)")
                            .font(.title2.bold())
                            .foregroundColor(stateColor(for: context.state.currentState))
                        Text("+\(context.state.pointsPerMinute)/min")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
                
                DynamicIslandExpandedRegion(.center) {
                    VStack(spacing: 4) {
                        Text(stateName(for: context.state.currentState))
                            .font(.headline)
                        Text(formatTime(context.state.elapsedSeconds))
                            .font(.title3.monospacedDigit())
                            .foregroundColor(.primary)
                    }
                }
                
                DynamicIslandExpandedRegion(.bottom) {
                    HStack {
                        Image(systemName: "figure.stand")
                            .foregroundColor(.secondary)
                        Text("\(Int(context.state.angle))° tilt")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Spacer()
                        Text("HeadsUp Session")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal)
                }
            } compactLeading: {
                // Compact leading (left side)
                PostureStateDot(state: context.state.currentState)
            } compactTrailing: {
                // Compact trailing (right side)
                Text(formatTime(context.state.elapsedSeconds))
                    .font(.caption2.monospacedDigit())
                    .foregroundColor(.secondary)
            } minimal: {
                // Minimal view (when another app has island)
                PostureStateDot(state: context.state.currentState)
            }
        }
    }
    
    // Helper: Format elapsed time
    private func formatTime(_ seconds: Int) -> String {
        let hours = seconds / 3600
        let minutes = (seconds % 3600) / 60
        let secs = seconds % 60
        
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, secs)
        } else {
            return String(format: "%d:%02d", minutes, secs)
        }
    }
    
    // Helper: Get state color
    private func stateColor(for state: String) -> Color {
        switch state {
        case "excellent": return Color(red: 0, green: 0.78, blue: 0.33)  // #00C853
        case "good": return Color(red: 0.20, green: 0.78, blue: 0.35)    // #34C759
        case "okay": return Color(red: 1.0, green: 0.84, blue: 0.04)     // #FFD60A
        case "bad": return Color(red: 1.0, green: 0.58, blue: 0)         // #FF9500
        case "poor": return Color(red: 1.0, green: 0.23, blue: 0.19)     // #FF3B30
        default: return .gray
        }
    }
    
    // Helper: Get state name
    private func stateName(for state: String) -> String {
        switch state {
        case "excellent": return "Excellent 🌟"
        case "good": return "Good"
        case "okay": return "Okay"
        case "bad": return "Bad"
        case "poor": return "Poor"
        default: return "Tracking"
        }
    }
}

// Posture state dot indicator
struct PostureStateDot: View {
    let state: String
    
    var body: some View {
        Circle()
            .fill(color)
            .frame(width: 12, height: 12)
    }
    
    private var color: Color {
        switch state {
        case "excellent": return Color(red: 0, green: 0.78, blue: 0.33)
        case "good": return Color(red: 0.20, green: 0.78, blue: 0.35)
        case "okay": return Color(red: 1.0, green: 0.84, blue: 0.04)
        case "bad": return Color(red: 1.0, green: 0.58, blue: 0)
        case "poor": return Color(red: 1.0, green: 0.23, blue: 0.19)
        default: return .gray
        }
    }
}

// Posture state icon
struct PostureStateIcon: View {
    let state: String
    
    var body: some View {
        Image(systemName: iconName)
            .font(.title2)
            .foregroundColor(color)
    }
    
    private var iconName: String {
        switch state {
        case "excellent": return "star.fill"
        case "good": return "checkmark.circle.fill"
        case "okay": return "minus.circle.fill"
        case "bad": return "exclamationmark.triangle.fill"
        case "poor": return "xmark.circle.fill"
        default: return "circle.fill"
        }
    }
    
    private var color: Color {
        switch state {
        case "excellent": return Color(red: 0, green: 0.78, blue: 0.33)
        case "good": return Color(red: 0.20, green: 0.78, blue: 0.35)
        case "okay": return Color(red: 1.0, green: 0.84, blue: 0.04)
        case "bad": return Color(red: 1.0, green: 0.58, blue: 0)
        case "poor": return Color(red: 1.0, green: 0.23, blue: 0.19)
        default: return .gray
        }
    }
}

// Lock screen view
struct PostureLockScreenView: View {
    let context: ActivityViewContext<PostureActivityAttributes>
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                PostureStateIcon(state: context.state.currentState)
                Text(stateName(for: context.state.currentState))
                    .font(.headline)
                Spacer()
                Text(formatTime(context.state.elapsedSeconds))
                    .font(.subheadline.monospacedDigit())
            }
            
            HStack {
                Text("Points: +\(context.state.totalPoints)")
                    .font(.caption)
                Spacer()
                Text("\(Int(context.state.angle))° tilt")
                    .font(.caption)
            }
            .foregroundColor(.secondary)
        }
        .padding()
    }
    
    private func formatTime(_ seconds: Int) -> String {
        let hours = seconds / 3600
        let minutes = (seconds % 3600) / 60
        let secs = seconds % 60
        
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, secs)
        } else {
            return String(format: "%d:%02d", minutes, secs)
        }
    }
    
    private func stateName(for state: String) -> String {
        switch state {
        case "excellent": return "Excellent Posture 🌟"
        case "good": return "Good Posture"
        case "okay": return "Okay Posture"
        case "bad": return "Bad Posture"
        case "poor": return "Poor Posture"
        default: return "Tracking Posture"
        }
    }
}
