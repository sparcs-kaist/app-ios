//
//  soapApp.swift
//  soap
//
//  Created by Soongyu Kwon on 28/10/2024.
//

import SwiftUI
import SwiftyBeaver
import FirebaseCore
import FirebaseMessaging
import UserNotifications
import Factory
import BuddyDomain

let logger = SwiftyBeaver.self

// MARK: - Main-actor AppDelegate (no MessagingDelegate here)
class AppDelegate: NSObject, UIApplicationDelegate {
  // Keep a strong reference so it doesn't deallocate
  private let pushDelegate = PushDelegate()

  func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil
  ) -> Bool {
    FirebaseApp.configure()

    // Ask permission
    let center = UNUserNotificationCenter.current()
    center.delegate = pushDelegate
    center.requestAuthorization(options: [.alert, .badge, .sound]) { granted, _ in
      print("Notification permission granted: \(granted)")
    }

    UIApplication.shared.registerForRemoteNotifications()

    // FCM
    Messaging.messaging().delegate = pushDelegate

    return true
  }

  // APNs device token → FCM
  func application(_ application: UIApplication,
                   didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
    Messaging.messaging().apnsToken = deviceToken
  }
}

// MARK: - Non-actor-isolated delegate sink
final class PushDelegate: NSObject, UNUserNotificationCenterDelegate, MessagingDelegate {

  // Foreground presentation
  func userNotificationCenter(_ center: UNUserNotificationCenter,
                              willPresent notification: UNNotification,
                              withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
    completionHandler([.banner, .badge, .sound])
  }

  // Taps on notifications (optional)
  func userNotificationCenter(_ center: UNUserNotificationCenter,
                              didReceive response: UNNotificationResponse,
                              withCompletionHandler completionHandler: @escaping () -> Void) {
    // If you need UI work, hop to main:
    Task { @MainActor in
      // navigate / update state
    }
    completionHandler()
  }

  // FCM token updates
  // Mark nonisolated explicitly to avoid accidental main-actor capture
  nonisolated func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
    print("FCM token: \(String(describing: fcmToken))")
    // If you need to touch @MainActor state or UI:
    Task { @MainActor in
      // save to Keychain / send to server / update view model
    }
  }
}

@main
struct soapApp: App {
  @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
  @Injected(\.tokenBridgeService) private var tokenBridgeService: TokenBridgeServiceProtocol

  init() {
    // Initialise Console Logger (SwiftyBeaver)
    let console = ConsoleDestination()
    console.format = "$DHH:mm:ss$d $L $M"
    console.logPrintWay = .logger(subsystem: "Main", category: "UI")
    logger.addDestination(console)

    // watchOS support
    tokenBridgeService.start()
  }

  var body: some Scene {
    WindowGroup {
      ContentView()
    }
  }
}

