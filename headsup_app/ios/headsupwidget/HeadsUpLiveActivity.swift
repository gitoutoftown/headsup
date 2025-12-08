import ActivityKit
import SwiftUI
import WidgetKit
import os

// HeadsUpActivityAttributes is defined in HeadsUpActivityAttributes.swift

// Live Activity widget for Dynamic Island
@main
struct HeadsUpLiveActivity: Widget {
    let logger = Logger(subsystem: "com.headsup.headsupApp", category: "LiveActivity")

    init() {
        logger.info("HeadsUpLiveActivity initialized")
    }

    // Helper to safely check stale state
    func isActivityStale(_ context: ActivityViewContext<HeadsUpActivityAttributes>) -> Bool {
        if #available(iOS 16.2, *) {
            return context.isStale
        }
        return false
    }

    var body: some WidgetConfiguration {
        ActivityConfiguration(for: HeadsUpActivityAttributes.self) { context in
            // Lock screen / banner UI
            let stale = isActivityStale(context)
            
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: iconName(for: context.state.currentState))
                        .foregroundColor(stateColor(for: context.state.currentState))
                    Text(stale ? "Session Ended" : stateName(for: context.state.currentState))
                        .font(.headline)
                    Spacer()
                    if !stale {
                        Text(formatTime(context.state.elapsedSeconds))
                            .font(.subheadline.monospacedDigit())
                    }
                }
                
                if !stale {
                    HStack {
                        Text("Points: +\(context.state.totalPoints)")
                            .font(.caption)
                        Spacer()
                        Text("\(Int(context.state.angle))° tilt")
                            .font(.caption)
                    }
                    .foregroundColor(.secondary)
                }
            }
            .padding()
            .opacity(stale ? 0.5 : 1.0)
        } dynamicIsland: { context in
            let stale = isActivityStale(context)
            
            return DynamicIsland {
                // Expanded view (long press)
                DynamicIslandExpandedRegion(.leading) {
                    if !stale {
                        Image(systemName: iconName(for: context.state.currentState))
                            .font(.title2)
                            .foregroundColor(stateColor(for: context.state.currentState))
                    }
                }
                
                DynamicIslandExpandedRegion(.trailing) {
                    if !stale {
                        VStack(alignment: .trailing, spacing: 2) {
                            Text("+\(context.state.totalPoints)")
                                .font(.title2.bold())
                                .foregroundColor(stateColor(for: context.state.currentState))
                            Text("+\(context.state.pointsPerMinute)/min")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                DynamicIslandExpandedRegion(.center) {
                    VStack(spacing: 4) {
                        if stale {
                            Text("Session Ended")
                                .font(.headline)
                                .foregroundColor(.secondary)
                        } else {
                            Text(stateName(for: context.state.currentState))
                                .font(.headline)
                            Text(formatTime(context.state.elapsedSeconds))
                                .font(.title3.monospacedDigit())
                                .foregroundColor(.primary)
                        }
                    }
                }
                
                DynamicIslandExpandedRegion(.bottom) {
                    if !stale {
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
                }
            } compactLeading: {
                if !stale {
                    // Compact leading (left side)
                    Circle()
                        .fill(stateColor(for: context.state.currentState))
                        .frame(width: 12, height: 12)
                }
            } compactTrailing: {
                if stale {
                     Text("End")
                        .font(.caption2.bold())
                        .foregroundColor(.secondary)
                } else {
                    // Compact trailing (right side)
                    Text(formatTime(context.state.elapsedSeconds))
                        .font(.caption2.monospacedDigit())
                        .foregroundColor(.secondary)
                }
            } minimal: {
                if !stale {
                    // Minimal view (when another app has island)
                    Circle()
                        .fill(stateColor(for: context.state.currentState))
                        .frame(width: 12, height: 12)
                }
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
        case "good": return Color(red: 0.0, green: 0.48, blue: 1.0)      // #007AFF (Blue)
        case "okay": return Color(red: 1.0, green: 0.84, blue: 0.04)     // #FFD60A
        case "bad": return Color(red: 1.0, green: 0.58, blue: 0)         // #FF9500
        case "poor": return Color(red: 1.0, green: 0.23, blue: 0.19)     // #FF3B30
        default: return .gray
        }
    }
    
    // Helper: Get state name
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
    
    // Helper: Get icon name
    private func iconName(for state: String) -> String {
        switch state {
        case "excellent": return "star.fill"
        case "good": return "checkmark.circle.fill"
        case "okay": return "minus.circle.fill"
        case "bad": return "exclamationmark.triangle.fill"
        case "poor": return "xmark.circle.fill"
        default: return "circle.fill"
        }
    }
}
