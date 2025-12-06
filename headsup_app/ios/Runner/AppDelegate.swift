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
}
