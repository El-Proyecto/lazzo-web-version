import Flutter
import UIKit
import UserNotifications

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)
    
    // Request push notification permissions
    if #available(iOS 10.0, *) {
      UNUserNotificationCenter.current().delegate = self
      
      let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound]
      UNUserNotificationCenter.current().requestAuthorization(
        options: authOptions,
        completionHandler: { granted, error in
          if granted {
            print("[APNs] Push notification permission granted")
          } else {
            print("[APNs] Push notification permission denied")
          }
        }
      )
    } else {
      let settings: UIUserNotificationSettings =
        UIUserNotificationSettings(types: [.alert, .badge, .sound], categories: nil)
      application.registerUserNotificationSettings(settings)
    }
    
    // Register for remote notifications (APNs)
    application.registerForRemoteNotifications()
    
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
  
  // Called when APNs successfully registers device
  override func application(
    _ application: UIApplication,
    didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
  ) {
    let tokenParts = deviceToken.map { data in String(format: "%02.2hhx", data) }
    let token = tokenParts.joined()
    print("[APNs] Device Token: \(token)")
    
    // Send token to Flutter via MethodChannel
    if let controller = window?.rootViewController as? FlutterViewController {
      let channel = FlutterMethodChannel(
        name: "com.lazzo.app/push_notifications",
        binaryMessenger: controller.binaryMessenger
      )
      channel.invokeMethod("onTokenReceived", arguments: token)
    }
  }
  
  // Called when APNs registration fails
  override func application(
    _ application: UIApplication,
    didFailToRegisterForRemoteNotificationsWithError error: Error
  ) {
    print("[APNs] Failed to register: \(error)")
  }
  
  // Handle notification when app is in foreground
  override func userNotificationCenter(
    _ center: UNUserNotificationCenter,
    willPresent notification: UNNotification,
    withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
  ) {
    // Show notification even when app is in foreground
    if #available(iOS 14.0, *) {
      completionHandler([.banner, .sound, .badge])
    } else {
      completionHandler([.alert, .sound, .badge])
    }
  }
  
  // Handle notification tap (user interaction)
  override func userNotificationCenter(
    _ center: UNUserNotificationCenter,
    didReceive response: UNNotificationResponse,
    withCompletionHandler completionHandler: @escaping () -> Void
  ) {
    let userInfo = response.notification.request.content.userInfo
    
    // Extract deep link from notification payload
    if let deeplink = userInfo["deeplink"] as? String {
      print("[APNs] Deep link: \(deeplink)")
      
      // Send deep link to Flutter via MethodChannel
      if let controller = window?.rootViewController as? FlutterViewController {
        let channel = FlutterMethodChannel(
          name: "com.lazzo.app/push_notifications",
          binaryMessenger: controller.binaryMessenger
        )
        channel.invokeMethod("onNotificationTapped", arguments: deeplink)
      }
    }
    
    completionHandler()
  }
}

