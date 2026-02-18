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
import AppIntents

#if DEBUG
import FirebaseCrashlytics
#endif

let logger = SwiftyBeaver.self

// MARK: - Main-actor AppDelegate (no MessagingDelegate here)
class AppDelegate: NSObject, UIApplicationDelegate {
  // Keep a strong reference so it doesn't deallocate
  private let pushDelegate = PushDelegate()
  @Injected(\.authUseCase) private var authUseCase: AuthUseCaseProtocol?
  @Injected(\.userUseCase) private var userUseCase: UserUseCaseProtocol?

  func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil
  ) -> Bool {
    FirebaseApp.configure()

    // Firebase Crashlytics
    #if DEBUG
    Crashlytics.crashlytics().setCrashlyticsCollectionEnabled(false)
    #endif

    // Ask permission
    let center = UNUserNotificationCenter.current()
    center.delegate = pushDelegate
    center.requestAuthorization(options: [.alert, .badge, .sound]) { granted, _ in
      print("Notification permission granted: \(granted)")
    }

    UIApplication.shared.registerForRemoteNotifications()

    // FCM
    Messaging.messaging().delegate = pushDelegate

    // Refresh token and fetch users
    Task {
      try? await authUseCase?.refreshAccessToken(force: true)
      await userUseCase?.fetchUsers()
    }

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
  @Injected(\.fcmUseCase) private var fcmUseCase: FCMUseCaseProtocol?
  
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
    Task { @MainActor [fcmUseCase] in
      // save to Keychain / send to server / update view model
      guard let fcmToken else { return }
      
      do {
        try await fcmUseCase?.register(fcmToken: fcmToken)
      } catch {
        print("Failed to register fcm token: \(error)")
      }
    }
  }
}

@main
struct soapApp: App {
  @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
  @Injected(\.sessionBridgeService) private var sessionBridgeService: SessionBridgeServiceProtocol?

  init() {
    // Initialise Console Logger (SwiftyBeaver)
    let console = ConsoleDestination()
    console.format = "$DHH:mm:ss$d $L $M"
    console.logPrintWay = .logger(subsystem: "Main", category: "UI")
    logger.addDestination(console)

    // watchOS support
    if let sessionBridgeService {
      sessionBridgeService.start()
    }

    // App Intents
    BuddyShortcuts.updateAppShortcutParameters()
  }

  var body: some Scene {
    WindowGroup {
      ContentView()
    }
  }
}

