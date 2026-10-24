#if os(iOS)
import UIKit

/// A photo placed in the text. It keeps the original for upload and draws a rounded copy
/// sized to the text width, like a photo in Notes.
public final class TiptapImageAttachment: NSTextAttachment {
  /// Identifies the photo when the document is converted, e.g. to look up its uploaded URL.
  public let id = UUID()
  /// The photo as picked, uploaded when the post is sent.
  public let originalImage: UIImage

  private static let cornerRadius: CGFloat = 10
  /// Photos are drawn at most this tall, so a tall screenshot doesn't fill several screens.
  private static let maximumHeight: CGFloat = 480

  public init(image: UIImage) {
    self.originalImage = image
    super.init(data: nil, ofType: nil)
    self.image = Self.rounded(image)
  }

  required init?(coder: NSCoder) {
    fatalError("TiptapImageAttachment is not archived")
  }

  public override func attachmentBounds(
    for attributes: [NSAttributedString.Key: Any],
    location: any NSTextLocation,
    textContainer: NSTextContainer?,
    proposedLineFragment: CGRect,
    position: CGPoint
  ) -> CGRect {
    let size = originalImage.size
    guard size.width > 0, size.height > 0 else { return .zero }
    let padding = textContainer?.lineFragmentPadding ?? 0
    let availableWidth = max(proposedLineFragment.width - padding * 2, 1)
    var width = min(size.width, availableWidth)
    var height = width * size.height / size.width
    if height > Self.maximumHeight {
      height = Self.maximumHeight
      width = height * size.width / size.height
    }
    return CGRect(x: 0, y: 0, width: width, height: height)
  }

  /// The on-screen copy: downscaled, since a camera photo is far larger than it's ever drawn,
  /// and clipped to rounded corners.
  private static func rounded(_ image: UIImage) -> UIImage {
    let maximumPixelWidth: CGFloat = 1600
    let pixelWidth = image.size.width * image.scale
    let pixelScale = min(1, maximumPixelWidth / max(pixelWidth, 1))
    let size = CGSize(width: image.size.width * image.scale * pixelScale, height: image.size.height * image.scale * pixelScale)

    let format = UIGraphicsImageRendererFormat.preferred()
    format.scale = 1
    return UIGraphicsImageRenderer(size: size, format: format).image { _ in
      let rect = CGRect(origin: .zero, size: size)
      // Drawn at roughly a third of its pixel width on screen, so the radius scales to match.
      UIBezierPath(roundedRect: rect, cornerRadius: cornerRadius * max(size.width / 400, 1)).addClip()
      image.draw(in: rect)
    }
  }
}
#endif
