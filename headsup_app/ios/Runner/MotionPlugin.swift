import Flutter
import UIKit
import CoreMotion
import AudioToolbox

/// Flutter plugin for accessing CMDeviceMotion sensor fusion
public class MotionPlugin: NSObject, FlutterPlugin, FlutterStreamHandler {
    
    private var motionManager: CMMotionManager?
    private var eventSink: FlutterEventSink?
    private var updateInterval: TimeInterval = 0.2 // 5 Hz (every 200ms)
    
    public static func register(with registrar: FlutterPluginRegistrar) {
        let instance = MotionPlugin()
        
        // Method channel for start/stop commands
        let methodChannel = FlutterMethodChannel(
            name: "com.headsup/motion",
            binaryMessenger: registrar.messenger()
        )
        registrar.addMethodCallDelegate(instance, channel: methodChannel)
        
        // Event channel for streaming sensor data
        let eventChannel = FlutterEventChannel(
            name: "com.headsup/motion_stream",
            binaryMessenger: registrar.messenger()
        )
        eventChannel.setStreamHandler(instance)
    }
    
    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "startMotionUpdates":
            if let args = call.arguments as? [String: Any],
               let interval = args["interval"] as? Double {
                updateInterval = interval
            }
            startMotionUpdates()
            result(true)
            
        case "stopMotionUpdates":
            stopMotionUpdates()
            result(true)
            
        case "isDeviceMotionAvailable":
            let available = CMMotionManager().isDeviceMotionAvailable
            result(available)
            
        case "vibrate":
            // kSystemSoundID_Vibrate = 4095
            AudioServicesPlaySystemSound(kSystemSoundID_Vibrate)
            result(true)
            
        default:
            result(FlutterMethodNotImplemented)
        }
    }
    
    // MARK: - FlutterStreamHandler
    
    public func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        self.eventSink = events
        return nil
    }
    
    public func onCancel(withArguments arguments: Any?) -> FlutterError? {
        self.eventSink = nil
        return nil
    }
    
    // MARK: - Motion Updates
    
    private func startMotionUpdates() {
        if motionManager == nil {
            motionManager = CMMotionManager()
        }
        
        guard let manager = motionManager else { return }
        
        if !manager.isDeviceMotionAvailable {
            eventSink?(FlutterError(
                code: "UNAVAILABLE",
                message: "Device motion is not available on this device",
                details: nil
            ))
            return
        }
        
        manager.deviceMotionUpdateInterval = updateInterval
        
        manager.startDeviceMotionUpdates(
            using: .xArbitraryZVertical,
            to: OperationQueue.main
        ) { [weak self] (motion, error) in
            guard let self = self, let motion = motion else {
                if let error = error {
                    self?.eventSink?(FlutterError(
                        code: "MOTION_ERROR",
                        message: error.localizedDescription,
                        details: nil
                    ))
                }
                return
            }
            
            // Get attitude (orientation) from CMDeviceMotion
            let attitude = motion.attitude
            
            // Convert radians to degrees
            let pitchDegrees = attitude.pitch * 180.0 / .pi
            let rollDegrees = attitude.roll * 180.0 / .pi
            let yawDegrees = attitude.yaw * 180.0 / .pi
            
            // Get gravity vector for context detection
            let gravity = motion.gravity
            
            // Get user acceleration for movement detection
            let userAcceleration = motion.userAcceleration
            let accelerationMagnitude = sqrt(
                userAcceleration.x * userAcceleration.x +
                userAcceleration.y * userAcceleration.y +
                userAcceleration.z * userAcceleration.z
            )
            
            // Send data to Flutter
            let data: [String: Any] = [
                "pitch": pitchDegrees,
                "roll": rollDegrees,
                "yaw": yawDegrees,
                "gravityX": gravity.x,
                "gravityY": gravity.y,
                "gravityZ": gravity.z,
                "accelerationMagnitude": accelerationMagnitude,
                "timestamp": motion.timestamp
            ]
            
            self.eventSink?(data)
        }
    }
    
    private func stopMotionUpdates() {
        motionManager?.stopDeviceMotionUpdates()
    }
}
