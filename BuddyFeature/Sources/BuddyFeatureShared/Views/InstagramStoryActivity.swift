import UIKit

/// Opens Instagram's story composer with the transparent image as a movable sticker.
// UIKit serializes activity callbacks on the main thread. The unchecked
// conformance bridges UIActivity's unannotated callbacks to UIApplication.
public final class InstagramStoryActivity: UIActivity, @unchecked Sendable {
  public static let type = UIActivity.ActivityType("org.sparcs.soap.instagramStory")

  private let shareURL: URL?
  private let backgroundTopColorHex: String
  private let backgroundBottomColorHex: String
  private var stickerData: Data?

  public init(appID: String, backgroundColorHex: String = "F2F2F7") {
    let hex = backgroundColorHex.trimmingCharacters(in: CharacterSet(charactersIn: "#"))
    let rgb = UInt32(hex, radix: 16) ?? 0xF2F2F7
    // A little white above and black below keeps the gradient close to the theme.
    backgroundTopColorHex = Self.blendedHex(rgb, toward: 255, amount: 0.08)
    backgroundBottomColorHex = Self.blendedHex(rgb, toward: 0, amount: 0.06)
    var components = URLComponents()
    components.scheme = "instagram-stories"
    components.host = "share"
    components.queryItems = [URLQueryItem(name: "source_application", value: appID)]
    shareURL = components.url
    super.init()
  }

  private static func blendedHex(_ rgb: UInt32, toward target: Double, amount: Double) -> String {
    let channels = [16, 8, 0].map { shift in
      let value = Double((rgb >> shift) & 0xFF)
      return Int((value + (target - value) * amount).rounded())
    }
    return String(format: "#%02X%02X%02X", channels[0], channels[1], channels[2])
  }

  public override class var activityCategory: UIActivity.Category { .action }
  public override var activityType: UIActivity.ActivityType? { Self.type }
  public override var activityTitle: String? {
    String(localized: "Share to Instagram Story", bundle: .module)
  }
  public override var activityImage: UIImage? { UIImage(systemName: "camera") }

  public override func canPerform(withActivityItems activityItems: [Any]) -> Bool {
    let containsImage = Self.image(in: activityItems) != nil
    return MainActor.assumeIsolated {
      guard let shareURL, UIApplication.shared.canOpenURL(shareURL) else { return false }
      return containsImage
    }
  }

  public override func prepare(withActivityItems activityItems: [Any]) {
    stickerData = Self.image(in: activityItems)?.pngData()
  }

  private static func image(in activityItems: [Any]) -> UIImage? {
    // Availability checks can receive the original item source, while prepare
    // can receive its resolved UIImage. Handle both stages consistently.
    activityItems.lazy.compactMap { item in
      if let source = item as? ImageActivityItemSource { return source.instagramStoryImage }
      return item as? UIImage
    }.first
  }

  public override func perform() {
    // UIActivity invokes these callbacks on the main thread, but its SDK
    // declarations do not carry main-actor annotations.
    MainActor.assumeIsolated { openStoryComposer() }
  }

  @MainActor private func openStoryComposer() {
    guard let shareURL, let stickerData, UIApplication.shared.canOpenURL(shareURL) else {
      activityDidFinish(false)
      return
    }

    UIPasteboard.general.setItems(
      [[
        "com.instagram.sharedSticker.stickerImage": stickerData,
        "com.instagram.sharedSticker.backgroundTopColor": backgroundTopColorHex,
        "com.instagram.sharedSticker.backgroundBottomColor": backgroundBottomColorHex
      ]],
      options: [.expirationDate: Date().addingTimeInterval(300)]
    )
    UIApplication.shared.open(shareURL, options: [:]) { [self] opened in
      // Success means the composer opened; the user still chooses whether to post.
      activityDidFinish(opened)
    }
  }
}
