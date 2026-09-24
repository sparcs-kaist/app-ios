import UIKit

/// Opens Instagram's story composer with the transparent image as a movable sticker.
// UIKit serializes activity callbacks on the main thread. The unchecked
// conformance bridges UIActivity's unannotated callbacks to UIApplication.
public final class InstagramStoryActivity: UIActivity, @unchecked Sendable {
  public static let type = UIActivity.ActivityType("org.sparcs.soap.instagramStory")

  private let shareURL: URL?
  private var stickerData: Data?

  public init(appID: String) {
    var components = URLComponents()
    components.scheme = "instagram-stories"
    components.host = "share"
    components.queryItems = [URLQueryItem(name: "source_application", value: appID)]
    shareURL = components.url
    super.init()
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
      if let source = item as? ImageActivityItemSource { return source.image }
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
        "com.instagram.sharedSticker.backgroundTopColor": "#F2F2F7",
        "com.instagram.sharedSticker.backgroundBottomColor": "#F2F2F7"
      ]],
      options: [.expirationDate: Date().addingTimeInterval(300)]
    )
    UIApplication.shared.open(shareURL, options: [:]) { [self] opened in
      // Success means the composer opened; the user still chooses whether to post.
      activityDidFinish(opened)
    }
  }
}
