//
//  soapApp.swift
//  soap
//
//  Created by Soongyu Kwon on 28/10/2024.
//

import SwiftUI
import Combine
import os
import FirebaseCore
import FirebaseMessaging
import UserNotifications
import Intents
import Factory
import BuddyDomain
import BuddyDataCore
import AppIntents
import FirebaseAnalytics
import SwiftData
import ChannelIOFront
import FirebaseCrashlytics
import BuddyFeatureShared

let logger = Logger(subsystem: "org.sparcs.soap", category: "App")

// MARK: - Main-actor AppDelegate (no MessagingDelegate here)
class AppDelegate: NSObject, UIApplicationDelegate {
  // Keep a strong reference so it doesn't deallocate
  private let pushDelegate = PushDelegate()
  private var signInObservation: AnyCancellable?
  @Injected(\.authUseCase) private var authUseCase: AuthUseCaseProtocol?
  @Injected(\.userUseCase) private var userUseCase: UserUseCaseProtocol?

  func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil
  ) -> Bool {
    FirebaseApp.configure()

    // Taxi notifications are localized by the notification service extension, which cannot see
    // the language chosen for Buddy alone in Settings, so it is shared through the app group.
    UserDefaults(suiteName: "group.org.sparcs.soap")?
      .set(Bundle.main.preferredLocalizations.first, forKey: "appLanguage")

    // Firebase Crashlytics
    Crashlytics.crashlytics().setCrashlyticsCollectionEnabled(false)

    Analytics.setAnalyticsCollectionEnabled(true)

    // Ask permission
    let center = UNUserNotificationCenter.current()
    center.delegate = pushDelegate
    center.setNotificationCategories([TaxiNotification.category])
    center.requestAuthorization(options: [.alert, .badge, .sound]) { granted, _ in
      logger.info("Notification permission granted: \(granted)")
    }

    UIApplication.shared.registerForRemoteNotifications()

    // FCM
    Messaging.messaging().delegate = pushDelegate
    // Signing out unregisters this device, and no new token arrives on signing back in, so the
    // current one is registered then. At launch the delegate above registers it.
    // Received on main first, as the closures below are main-actor isolated and the value is sent
    // from the auth actor.
    signInObservation = authUseCase?.isAuthenticatedPublisher
      .receive(on: DispatchQueue.main)
      .removeDuplicates()
      .dropFirst()
      .filter { $0 }
      .sink { [pushDelegate] _ in pushDelegate.registerCurrentToken() }

    // Refresh token and fetch users
    Task {
      try? await authUseCase?.refreshAccessToken(force: true)
      await userUseCase?.fetchUsers()
			
			// ChannelTalk
			ChannelIO.initialize(application)
			
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
  
  @Injected(\.taxiQuickReplyUseCase) private var taxiQuickReplyUseCase: TaxiQuickReplyUseCaseProtocol?

  // Foreground presentation. The system calls these delegate methods on the main thread, and
  // UIKit expects their completion handlers to be called there too: an async variant runs off it
  // and crashes the app when the notification is handled.
  func userNotificationCenter(
    _ center: UNUserNotificationCenter,
    willPresent notification: UNNotification,
    withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
  ) {
    guard let roomID = TaxiNotification.roomID(of: notification.request.content) else {
      completionHandler([.banner, .badge, .sound])
      return
    }
    // The open chat already shows the message, and while the app is open the unread store keeps
    // the app badge, so a Taxi push changes neither.
    let activeRoomID = MainActor.assumeIsolated { Container.shared.taxiUnreadStore()?.activeRoomID }
    completionHandler(activeRoomID == roomID ? [] : [.banner, .list, .sound])
  }

  // Taps and actions on notifications
  func userNotificationCenter(
    _ center: UNUserNotificationCenter,
    didReceive response: UNNotificationResponse,
    withCompletionHandler completionHandler: @escaping () -> Void
  ) {
    let content = response.notification.request.content
    guard let roomID = TaxiNotification.roomID(of: content) else {
      completionHandler()
      return
    }

    switch response.actionIdentifier {
    case TaxiNotification.replyActionIdentifier:
      guard let text = (response as? UNTextInputNotificationResponse)?.userText else {
        completionHandler()
        return
      }
      let roomName = content.userInfo["room_name"] as? String ?? content.title
      let useCase = taxiQuickReplyUseCase
      // Called here on the main thread and in the task on the main actor, so never concurrently.
      nonisolated(unsafe) let completionHandler = completionHandler
      MainActor.assumeIsolated {
        Task { @MainActor in
          await Self.reply(text, roomID: roomID, roomName: roomName, using: useCase)
          completionHandler()
        }
      }
    case UNNotificationDefaultActionIdentifier:
      MainActor.assumeIsolated {
        PendingDeepLink.post(.taxiChat(roomID: roomID))
      }
      completionHandler()
    default:
      completionHandler()
    }
  }

  /// Sends a reply typed into a Taxi notification. The system keeps the app running until the
  /// completion handler is called, even when the reply launched it in the background.
  @MainActor
  private static func reply(
    _ text: String,
    roomID: String,
    roomName: String,
    using useCase: TaxiQuickReplyUseCaseProtocol?
  ) async {
    do {
      try await useCase?.reply(text, roomID: roomID)
      Container.shared.taxiUnreadStore()?.markRead(roomID)
    } catch {
      logger.error("Failed to send a quick reply: \(error.localizedDescription, privacy: .public)")
      // Without this the reply would vanish silently; the notification keeps the reply action, so
      // it can be sent again.
      let failure = UNMutableNotificationContent()
      failure.title = roomName
      failure.body = String(localized: "Your reply couldn’t be sent. Tap Reply to try again.")
      failure.threadIdentifier = roomID
      failure.categoryIdentifier = TaxiNotification.categoryIdentifier
      failure.userInfo = ["category": "taxi_chat", "room_id": roomID, "room_name": roomName]
      // One per room, so failing again replaces it rather than adding another.
      try? await UNUserNotificationCenter.current().add(
        UNNotificationRequest(identifier: "taxi_reply_failed.\(roomID)", content: failure, trigger: nil)
      )
    }
  }

  /// Registers this device's current token, such as after signing in, when no new token arrives.
  @MainActor
  func registerCurrentToken() {
    Task { @MainActor [fcmUseCase] in
      do {
        let fcmToken = try await Messaging.messaging().token()
        try await fcmUseCase?.register(fcmToken: fcmToken)
      } catch {
        logger.error("Failed to register fcm token after signing in: \(error.localizedDescription, privacy: .public)")
      }
    }
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
  @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
  @Injected(\.sessionBridgeService) private var sessionBridgeService: SessionBridgeServiceProtocol?

  init() {
    // watchOS support
    if let sessionBridgeService {
      sessionBridgeService.start()
    }

    // App Intents
    BuddyShortcuts.updateAppShortcutParameters()

    // SwiftData – timetable cache
    TimetableCacheContainer.shared = try? TimetableCacheContainer.makeContainer()

    // TipKit
    BuddyTips.configure()
  }

  var body: some Scene {
    WindowGroup {
      ContentView()
    }
  }
}


// MARK: - Taxi notifications
/// Taxi chat and room notifications, which the Taxi server sends through Buddy's backend with the
/// room in their data and `TAXI_CHAT` as their category.
enum TaxiNotification {
  static let categoryIdentifier = "TAXI_CHAT"
  static let replyActionIdentifier = "TAXI_REPLY"

  /// Lets you reply to a ride's chat from its notification. Unlocking is required, since sending
  /// needs your sign-in, which is only readable while the device is unlocked.
  static var category: UNNotificationCategory {
    let reply = UNTextInputNotificationAction(
      identifier: replyActionIdentifier,
      title: String(localized: "Reply"),
      options: [.authenticationRequired],
      icon: UNNotificationActionIcon(systemImageName: "arrowshape.turn.up.left"),
      textInputButtonTitle: String(localized: "Send"),
      textInputPlaceholder: String(localized: "Message")
    )
    return UNNotificationCategory(
      identifier: categoryIdentifier,
      actions: [reply],
      intentIdentifiers: [INSendMessageIntentIdentifier],
      options: []
    )
  }

  /// The room a Taxi notification is about, or `nil` for any other notification.
  static func roomID(of content: UNNotificationContent) -> String? {
    guard let category = content.userInfo["category"] as? String,
          category.hasPrefix("taxi_") else {
      return nil
    }
    return content.userInfo["room_id"] as? String
  }
}
