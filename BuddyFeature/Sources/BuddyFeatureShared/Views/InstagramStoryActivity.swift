import UIKit

/// Opens Instagram's story composer with the transparent image as a movable sticker.
// UIKit serializes activity callbacks on the main thread. The unchecked
// conformance bridges UIActivity's unannotated callbacks to UIApplication.
public final class InstagramStoryActivity: UIActivity, @unchecked Sendable {
  public static let type = UIActivity.ActivityType("org.sparcs.soap.instagramStory")

  private let appID: String
  private let backgroundColorHex: String
  private var stickerData: Data?

  public init(appID: String, backgroundColorHex: String = "F2F2F7") {
    self.appID = appID
    self.backgroundColorHex = backgroundColorHex
    super.init()
  }

  public override class var activityCategory: UIActivity.Category { .action }
  public override var activityType: UIActivity.ActivityType? { Self.type }
  public override var activityTitle: String? {
    String(localized: "Share to Instagram Stories", bundle: .module)
  }
  public override var activityImage: UIImage? { UIImage(systemName: "camera") }

  public override func canPerform(withActivityItems activityItems: [Any]) -> Bool {
    let containsImage = Self.image(in: activityItems) != nil
    return MainActor.assumeIsolated {
      containsImage && InstagramStory.isAvailable(appID: appID)
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
    guard let stickerData else {
      activityDidFinish(false)
      return
    }
    Task { [self] in
      let opened = await InstagramStory.share(
        stickerData: stickerData,
        backgroundColorHex: backgroundColorHex,
        appID: appID
      )
      activityDidFinish(opened)
    }
  }
}
