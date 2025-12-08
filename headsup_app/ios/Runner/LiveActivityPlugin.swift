import Flutter
import UIKit
import ActivityKit

@available(iOS 16.1, *)
class LiveActivityPlugin: NSObject, FlutterPlugin {
    static var currentActivity: Activity<HeadsUpActivityAttributes>?
    
    static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(
            name: "com.headsup.live_activity",
            binaryMessenger: registrar.messenger()
        )
        let instance = LiveActivityPlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
    }
    
    func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard #available(iOS 16.1, *) else {
            result(FlutterError(
                code: "UNSUPPORTED",
                message: "Live Activities require iOS 16.1+",
                details: nil
            ))
            return
        }
        
        switch call.method {
        case "isSupported":
            result(true)
        case "startLiveActivity":
            startLiveActivity(call: call, result: result)
        case "updateLiveActivity":
            updateLiveActivity(call: call, result: result)
        case "endLiveActivity":
            endLiveActivity(result: result)
        default:
            result(FlutterMethodNotImplemented)
        }
    }
    
    @available(iOS 16.1, *)
    private func startLiveActivity(call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any],
              let sessionId = args["sessionId"] as? String,
              let currentState = args["currentState"] as? String,
              let totalPoints = args["totalPoints"] as? Int,
              let pointsPerMinute = args["pointsPerMinute"] as? Int,
              let angle = args["angle"] as? Double else {
            result(FlutterError(
                code: "INVALID_ARGS",
                message: "Missing required arguments",
                details: nil
            ))
            return
        }
        
        // Optional isPaused argument, defaults to false
        let isPaused = (args["isPaused"] as? Bool) ?? false
        
        let attributes = HeadsUpActivityAttributes(startTime: Date())
        let contentState = HeadsUpActivityAttributes.ContentState(
            sessionId: sessionId,
            elapsedSeconds: 0,
            currentState: currentState,
            totalPoints: totalPoints,
            pointsPerMinute: pointsPerMinute,
            angle: angle,
            isPaused: isPaused
        )
        
        do {
            let activity: Activity<HeadsUpActivityAttributes>
            
            if #available(iOS 16.2, *) {
                // Set stale date to 4 seconds from now (buffer for latency)
                // If app is alive (background or foreground), it updates every second, extending this.
                // If app dies, this expires shortly.
                let content = ActivityContent(state: contentState, staleDate: Date().addingTimeInterval(4))
                activity = try Activity<HeadsUpActivityAttributes>.request(
                    attributes: attributes,
                    content: content,
                    pushType: nil
                )
            } else {
                activity = try Activity<HeadsUpActivityAttributes>.request(
                    attributes: attributes,
                    contentState: contentState,
                    pushType: nil
                )
            }
            
            LiveActivityPlugin.currentActivity = activity
            DispatchQueue.main.async {
                result(true)
            }
            print("Live Activity started: \(activity.id)")
        } catch {
            result(FlutterError(
                code: "START_FAILED",
                message: "Failed to start Live Activity: \(error.localizedDescription)",
                details: nil
            ))
        }
    }
    
    @available(iOS 16.1, *)
    private func updateLiveActivity(call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let activity = LiveActivityPlugin.currentActivity else {
            result(FlutterError(
                code: "NO_ACTIVITY",
                message: "No active Live Activity to update",
                details: nil
            ))
            return
        }
        
        guard let args = call.arguments as? [String: Any],
              let elapsedSeconds = args["elapsedSeconds"] as? Int,
              let currentState = args["currentState"] as? String,
              let totalPoints = args["totalPoints"] as? Int,
              let pointsPerMinute = args["pointsPerMinute"] as? Int,
              let angle = args["angle"] as? Double else {
            result(FlutterError(
                code: "INVALID_ARGS",
                message: "Missing required arguments",
                details: nil
            ))
            return
        }
        
        let isPaused = (args["isPaused"] as? Bool) ?? false
        
        let contentState = HeadsUpActivityAttributes.ContentState(
            sessionId: activity.contentState.sessionId,
            elapsedSeconds: elapsedSeconds,
            currentState: currentState,
            totalPoints: totalPoints,
            pointsPerMinute: pointsPerMinute,
            angle: angle,
            isPaused: isPaused
        )
        
        Task {
            if #available(iOS 16.2, *) {
                let content = ActivityContent(state: contentState, staleDate: Date().addingTimeInterval(4))
                await activity.update(content)
            } else {
                await activity.update(using: contentState)
            }
            
            DispatchQueue.main.async {
                result(true)
            }
        }
    }
    
    @available(iOS 16.1, *)
    private func endLiveActivity(result: @escaping FlutterResult) {
        guard let activity = LiveActivityPlugin.currentActivity else {
            result(FlutterError(
                code: "NO_ACTIVITY",
                message: "No active Live Activity to end",
                details: nil
            ))
            return
        }
        
        Task {
            await activity.end(dismissalPolicy: .immediate)
            LiveActivityPlugin.currentActivity = nil
            DispatchQueue.main.async {
                result(true)
                print("Live Activity ended")
            }
        }
    }
}
