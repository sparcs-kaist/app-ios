//
//  soapApp.swift
//  soap
//
//  Created by Soongyu Kwon on 28/10/2024.
//

import SwiftUI
import os
import FirebaseCore
import FirebaseMessaging
import UserNotifications
import Factory
import BuddyDomain
import BuddyDataCore
import BuddyFeatureSettings
import AppIntents
import FirebaseAnalytics
import SwiftData
import FirebaseCrashlytics
#if os(iOS)
// ChannelTalk ships an iOS-only xcframework; macOS uses the web messenger instead.
import ChannelIOFront
#endif

let logger = Logger(subsystem: "org.sparcs.soap", category: "App")

#if os(iOS)
typealias PlatformApplicationDelegate = UIApplicationDelegate
#elseif os(macOS)
typealias PlatformApplicationDelegate = NSApplicationDelegate
#endif

// MARK: - Main-actor AppDelegate (no MessagingDelegate here)
class AppDelegate: NSObject, PlatformApplicationDelegate {
  // Keep a strong reference so it doesn't deallocate
  private let pushDelegate = PushDelegate()
  @Injected(\.authUseCase) private var authUseCase: AuthUseCaseProtocol?
  @Injected(\.userUseCase) private var userUseCase: UserUseCaseProtocol?

  #if os(iOS)
  func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil
  ) -> Bool {
    bootstrap()
    return true
  }

  // APNs device token → FCM
  func application(_ application: UIApplication,
                   didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
    Messaging.messaging().apnsToken = deviceToken
  }

  #elseif os(macOS)
  func applicationDidFinishLaunching(_ notification: Notification) {
    bootstrap()
  }

  // APNs device token → FCM
  func application(_ application: NSApplication,
                   didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
    Messaging.messaging().apnsToken = deviceToken
  }
  #endif

  /// Shared launch work. Split out of the delegate callbacks because UIKit and
  /// AppKit spell those differently but the setup itself is identical.
  ///
  /// `@MainActor` is explicit here: the delegate callbacks this is called from are
  /// main-actor isolated, and extracting the body into a plain method would
  /// otherwise make it `nonisolated` and the `Task` below a data race.
  @MainActor
  private func bootstrap() {
    FirebaseApp.configure()

    // Firebase Crashlytics
    Crashlytics.crashlytics().setCrashlyticsCollectionEnabled(false)

    Analytics.setAnalyticsCollectionEnabled(true)

    // Ask permission
    let center = UNUserNotificationCenter.current()
    center.delegate = pushDelegate
    center.requestAuthorization(options: [.alert, .badge, .sound]) { granted, _ in
      logger.info("Notification permission granted: \(granted)")
    }

    #if os(iOS)
    UIApplication.shared.registerForRemoteNotifications()
    #elseif os(macOS)
    NSApplication.shared.registerForRemoteNotifications()
    #endif

    // FCM
    Messaging.messaging().delegate = pushDelegate

    // Refresh token and fetch users
    Task {
      try? await authUseCase?.refreshAccessToken(force: true)
      await userUseCase?.fetchUsers()

			#if os(iOS)
			// ChannelTalk
			ChannelIO.initialize(UIApplication.shared)

			let profile = await CHTProfile()
				.set(name: userUseCase?.taxiUser?.name ?? "Unknown")
				.set(email: userUseCase?.taxiUser?.email ?? "Unknown")
				.set(mobileNumber: userUseCase?.taxiUser?.phoneNumber ?? "Unknown")
			
			let bootConfig = await CHTBootConfig(
				pluginKey: "b817c62b-ceb6-42a2-9781-d335b96f576f",
				memberId: userUseCase?.feedUser?.id,
				memberHash: nil,
				profile: profile,
				channelButtonOption: nil,
				hidePopup: false,
				trackDefaultEvent: true,
				language: .device
			)
			
			ChannelIO.boot(with: bootConfig)
			ChannelIO.hideChannelButton()
			#endif
    }
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
    logger.debug("FCM token: \(String(describing: fcmToken))")
    // If you need to touch @MainActor state or UI:
    Task { @MainActor [fcmUseCase] in
      // save to Keychain / send to server / update view model
      guard let fcmToken else { return }
      
      do {
        try await fcmUseCase?.register(fcmToken: fcmToken)
      } catch {
        logger.error("Failed to register fcm token: \(error.localizedDescription, privacy: .public)")
      }
    }
  }
}

@main
struct soapApp: App {
  #if os(iOS)
  @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
  #elseif os(macOS)
  @NSApplicationDelegateAdaptor(AppDelegate.self) var delegate
  #endif
  @Injected(\.sessionBridgeService) private var sessionBridgeService: SessionBridgeServiceProtocol?

  init() {
    // watchOS support
    if let sessionBridgeService {
      sessionBridgeService.start()
    }

    // App Intents
    BuddyShortcuts.updateAppShortcutParameters()

    // SwiftData – timetable cache
    TimetableCacheContainer.shared = try? ModelContainer(for: CachedTimetable.self)
  }

  var body: some Scene {
    WindowGroup {
      ContentView()
    }

    #if os(macOS)
    // Puts "Settings…" (⌘,) in the Buddy menu, which is where a Mac user looks for
    // it. On iOS the same screens stay behind the gear in the feed's toolbar.
    Settings {
      MacSettingsView()
    }
    #endif
  }
}

