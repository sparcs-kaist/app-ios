//
//  NotificationService.swift
//  NotificationServiceExtension
//
//  Created by 하정우 on 3/1/26.
//

import UserNotifications
import Intents
import FirebaseMessaging

class NotificationService: UNNotificationServiceExtension {

  var contentHandler: ((UNNotificationContent) -> Void)?
  var bestAttemptContent: UNMutableNotificationContent?
  private var delivery: Delivery?

  override func didReceive(_ request: UNNotificationRequest, withContentHandler contentHandler: @escaping (UNNotificationContent) -> Void) {
    self.contentHandler = contentHandler
    guard let bestAttemptContent = request.content.mutableCopy() as? UNMutableNotificationContent else {
      contentHandler(request.content)
      return
    }
    self.bestAttemptContent = bestAttemptContent

    // A ride event only needs its text in the app's language; see `localizedBody(of:)`.
    if TaxiChatNotification.isTaxiEvent(bestAttemptContent) {
      bestAttemptContent.body = TaxiChatNotification.localizedBody(of: bestAttemptContent)
      // Missing it means missing the ride, so it isn't held back by a Focus or the summary.
      if TaxiChatNotification.isDepartureReminder(bestAttemptContent) {
        bestAttemptContent.interruptionLevel = .timeSensitive
      }
      contentHandler(bestAttemptContent)
      return
    }

    guard TaxiChatNotification.isTaxiChat(bestAttemptContent) else {
      Messaging.serviceExtension().populateNotificationContent(bestAttemptContent, withContentHandler: contentHandler)
      return
    }

    // The conversation is built on a copy, so the best attempt delivered if time runs out isn't
    // being changed at the same time; whichever comes first is delivered, and only once.
    bestAttemptContent.body = TaxiChatNotification.localizedBody(of: bestAttemptContent)
    guard let conversation = bestAttemptContent.mutableCopy() as? UNMutableNotificationContent else {
      contentHandler(bestAttemptContent)
      return
    }
    let delivery = Delivery(contentHandler)
    self.delivery = delivery
    Task {
      delivery.deliver(await TaxiChatNotification.conversation(from: conversation))
    }
  }

  override func serviceExtensionTimeWillExpire() {
    // Called just before the extension will be terminated by the system.
    // Use this as an opportunity to deliver your "best attempt" at modified content, otherwise the original push payload will be used.
    if let delivery, let bestAttemptContent {
      delivery.deliver(bestAttemptContent)
    } else if let contentHandler = contentHandler, let bestAttemptContent = bestAttemptContent {
      contentHandler(bestAttemptContent)
    }
  }
}

/// Hands content to the system once, from whichever of the conversation and the time running out
/// gets there first.
private final class Delivery: @unchecked Sendable {
  private let lock = NSLock()
  private var contentHandler: ((UNNotificationContent) -> Void)?

  init(_ contentHandler: @escaping (UNNotificationContent) -> Void) {
    self.contentHandler = contentHandler
  }

  func deliver(_ content: UNNotificationContent) {
    let handler = lock.withLock {
      defer { contentHandler = nil }
      return contentHandler
    }
    handler?(content)
  }
}

/// Turns a Taxi chat push into a communication notification: shown as the ride's group
/// conversation, with the sender's photo, and a preview of a photo they sent.
///
/// Everything needed comes in the push's data, sent by the Taxi server through Buddy's backend, so
/// nothing here needs your sign-in.
enum TaxiChatNotification {
  static func isTaxiChat(_ content: UNNotificationContent) -> Bool {
    content.userInfo["category"] as? String == "taxi_chat"
  }

  static func isTaxiEvent(_ content: UNNotificationContent) -> Bool {
    content.userInfo["category"] as? String == "taxi_event"
  }

  /// The reminder that the taxi leaves soon, sent shortly before departure.
  static func isDepartureReminder(_ content: UNNotificationContent) -> Bool {
    isTaxiEvent(content) && content.userInfo["type"] as? String == "departure"
  }

  static func conversation(from content: UNMutableNotificationContent) async -> UNNotificationContent {
    let info = content.userInfo
    guard let roomID = info["room_id"] as? String else { return content }
    let roomName = info["room_name"] as? String
    let senderID = info["sender_id"] as? String ?? roomID
    let senderName = info["sender_name"] as? String ?? content.title

    async let avatar = download(info["sender_avatar_url"] as? String)
    async let photo = download(info["image_url"] as? String)

    content.body = localizedBody(of: content)
    if let attachment = await attachment(from: photo, roomID: roomID) {
      content.attachments = [attachment]
    }

    let sender = INPerson(
      personHandle: INPersonHandle(value: senderID, type: .unknown),
      nameComponents: nil,
      displayName: senderName,
      image: await avatar.map { INImage(imageData: $0) },
      contactIdentifier: nil,
      customIdentifier: senderID
    )
    let me = INPerson(
      personHandle: INPersonHandle(value: "me", type: .unknown),
      nameComponents: nil,
      displayName: nil,
      image: nil,
      contactIdentifier: nil,
      customIdentifier: nil,
      isMe: true
    )
    // A conversation with more than one recipient and a name is shown as a group: the ride's name
    // as the title, with the sender's name and photo on each message.
    let ride = INPerson(
      personHandle: INPersonHandle(value: roomID, type: .unknown),
      nameComponents: nil,
      displayName: roomName,
      image: nil,
      contactIdentifier: nil,
      customIdentifier: roomID
    )

    let intent = INSendMessageIntent(
      recipients: [me, ride],
      outgoingMessageType: .outgoingMessageText,
      content: content.body,
      speakableGroupName: roomName.map { INSpeakableString(spokenPhrase: $0) },
      conversationIdentifier: roomID,
      serviceName: nil,
      sender: sender,
      attachments: nil
    )

    let interaction = INInteraction(intent: intent, response: nil)
    interaction.direction = .incoming
    try? await interaction.donate()

    return (try? content.updating(from: intent)) ?? content
  }

  /// The text of a photo, an account number or a ride event, sent as a key localized in the app.
  ///
  /// The system would look the key up in the device's language, which differs from the app's when
  /// it was changed for Buddy alone in Settings, and this extension has no strings of its own; so
  /// it is looked up here, in the app's bundle, in the language the app last ran in.
  static func localizedBody(of content: UNNotificationContent) -> String {
    guard let aps = content.userInfo["aps"] as? [String: Any],
          let alert = aps["alert"] as? [String: Any],
          let key = alert["loc-key"] as? String else {
      return content.body
    }
    let format = appStrings.localizedString(forKey: key, value: content.body, table: nil)
    let arguments = (alert["loc-args"] as? [String]) ?? []
    return substitute(arguments, into: format)
  }

  /// Puts `arguments` into the `%@` and `%1$@` placeholders of `format`.
  ///
  /// Unlike `String(format:)`, a placeholder without an argument, or of another kind such as `%d`,
  /// is left as it is rather than read from memory that isn't there, since the arguments come from
  /// the push.
  static func substitute(_ arguments: [String], into format: String) -> String {
    var result = ""
    var nextArgument = 0
    var rest = Substring(format)
    while let percent = rest.firstIndex(of: "%") {
      result += rest[..<percent]
      let afterPercent = rest[rest.index(after: percent)...]
      if afterPercent.first == "%" {
        result += "%"
        rest = afterPercent.dropFirst()
      } else if afterPercent.first == "@" {
        result += nextArgument < arguments.count ? arguments[nextArgument] : "%@"
        nextArgument += 1
        rest = afterPercent.dropFirst()
      } else if let dollar = afterPercent.firstIndex(of: "$"),
                let position = Int(afterPercent[..<dollar]),
                afterPercent[afterPercent.index(after: dollar)...].first == "@" {
        let placeholder = rest[percent...afterPercent.index(after: dollar)]
        result += arguments.indices.contains(position - 1) ? arguments[position - 1] : String(placeholder)
        rest = afterPercent[afterPercent.index(dollar, offsetBy: 2)...]
      } else {
        result += "%"
        rest = afterPercent
      }
    }
    return result + rest
  }

  /// The app's strings in the language it last ran in, which the app records in the shared app
  /// group container as `appLanguage`.
  private static var appStrings: Bundle {
    let appBundle = Bundle(url: Bundle.main.bundleURL.deletingLastPathComponent().deletingLastPathComponent()) ?? .main
    guard let language = UserDefaults(suiteName: "group.org.sparcs.soap")?.string(forKey: "appLanguage"),
          let path = appBundle.path(forResource: language, ofType: "lproj"),
          let bundle = Bundle(path: path) else {
      return appBundle
    }
    return bundle
  }

  /// The largest image downloaded for a notification. The extension has little memory to spare.
  private static let maxImageBytes = 5 * 1024 * 1024

  /// Gives up on a download, however slowly it is still arriving, well before the extension's time
  /// runs out.
  private static let session: URLSession = {
    let configuration = URLSessionConfiguration.ephemeral
    configuration.timeoutIntervalForRequest = 10
    configuration.timeoutIntervalForResource = 15
    return URLSession(configuration: configuration)
  }()

  /// Downloads an image from the push, if it is one and isn't too big.
  private static func download(_ urlString: String?) async -> Data? {
    guard let urlString, let url = URL(string: urlString),
          let scheme = url.scheme?.lowercased(), scheme == "https" || scheme == "http" else {
      return nil
    }
    guard let (bytes, response) = try? await session.bytes(from: url),
          let response = response as? HTTPURLResponse,
          response.statusCode == 200,
          response.mimeType?.hasPrefix("image/") == true,
          response.expectedContentLength <= maxImageBytes else {
      return nil
    }
    var data = Data()
    do {
      for try await byte in bytes {
        data.append(byte)
        if data.count > maxImageBytes { return nil }
      }
    } catch {
      return nil
    }
    return data
  }

  private static func attachment(from data: Data?, roomID: String) async -> UNNotificationAttachment? {
    guard let data else { return nil }
    // Attachments are recognised by their extension, and chat photos are uploaded as JPEG.
    let url = FileManager.default.temporaryDirectory
      .appendingPathComponent(UUID().uuidString)
      .appendingPathExtension("jpg")
    do {
      try data.write(to: url)
      return try UNNotificationAttachment(identifier: "photo-\(roomID)", url: url)
    } catch {
      return nil
    }
  }
}
