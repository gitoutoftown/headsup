import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)
    
    // Register custom MotionPlugin for CMDeviceMotion access
    MotionPlugin.register(with: self.registrar(forPlugin: "MotionPlugin")!)
    
    // Register LiveActivityPlugin for Dynamic Island (iOS 16.1+)
    if #available(iOS 16.1, *) {
      LiveActivityPlugin.register(with: self.registrar(forPlugin: "LiveActivityPlugin")!)
    }
    
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
    
  override func applicationWillTerminate(_ application: UIApplication) {
    if #available(iOS 16.2, *) {
        // Attempt to end live activity immediately with RunLoop spin (prevents deadlock)
        if let activity = LiveActivityPlugin.currentActivity {
            var finished = false
            Task {
                await activity.end(dismissalPolicy: .immediate)
                finished = true
            }
            
            // Spin the run loop for up to 2 seconds to allow the async task to complete
            let timeout = Date().addingTimeInterval(2.0)
            while !finished && Date() < timeout {
                RunLoop.current.run(mode: .default, before: Date(timeIntervalSinceNow: 0.1))
            }
        }
    }
    super.applicationWillTerminate(application)
  }
}
