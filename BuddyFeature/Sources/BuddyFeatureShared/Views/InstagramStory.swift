import UIKit

/// Opens Instagram's story composer with an image as a movable sticker over a gradient of the
/// given colour.
@MainActor
public enum InstagramStory {
  /// Whether Instagram is installed and can take a story from this app.
  public static func isAvailable(appID: String) -> Bool {
    guard let url = shareURL(appID: appID) else { return false }
    return UIApplication.shared.canOpenURL(url)
  }

  /// Hands the sticker to Instagram and opens its composer. Returns whether the composer opened;
  /// the user still chooses whether to post.
  @discardableResult
  public static func share(stickerData: Data, backgroundColorHex: String, appID: String) async -> Bool {
    guard let url = shareURL(appID: appID), UIApplication.shared.canOpenURL(url) else { return false }
    let colors = backgroundColors(for: backgroundColorHex)
    UIPasteboard.general.setItems(
      [[
        "com.instagram.sharedSticker.stickerImage": stickerData,
        "com.instagram.sharedSticker.backgroundTopColor": colors.top,
        "com.instagram.sharedSticker.backgroundBottomColor": colors.bottom
      ]],
      options: [.expirationDate: Date().addingTimeInterval(300)]
    )
    return await UIApplication.shared.open(url)
  }

  private static func shareURL(appID: String) -> URL? {
    var components = URLComponents()
    components.scheme = "instagram-stories"
    components.host = "share"
    components.queryItems = [URLQueryItem(name: "source_application", value: appID)]
    return components.url
  }

  /// A little white above and black below keeps the gradient close to the theme.
  nonisolated static func backgroundColors(for hex: String) -> (top: String, bottom: String) {
    let hex = hex.trimmingCharacters(in: CharacterSet(charactersIn: "#"))
    let rgb = UInt32(hex, radix: 16) ?? 0xF2F2F7
    return (blendedHex(rgb, toward: 255, amount: 0.08), blendedHex(rgb, toward: 0, amount: 0.06))
  }

  private nonisolated static func blendedHex(_ rgb: UInt32, toward target: Double, amount: Double) -> String {
    let channels = [16, 8, 0].map { shift in
      let value = Double((rgb >> shift) & 0xFF)
      return Int((value + (target - value) * amount).rounded())
    }
    return String(format: "#%02X%02X%02X", channels[0], channels[1], channels[2])
  }
}
