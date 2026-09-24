import LinkPresentation
import UIKit
import UniformTypeIdentifiers

/// Shares a named PNG file with a title and image in the system share preview.
public final class ImageActivityItemSource: NSObject, UIActivityItemSource {
  // Custom activities may receive the source itself during availability checks.
  let image: UIImage
  private let title: String
  private let fileURL: URL

  public init(image: UIImage, title: String) throws {
    guard let data = image.pngData() else {
      throw CocoaError(.fileWriteUnknown)
    }

    let directory = FileManager.default.temporaryDirectory
      .appendingPathComponent(UUID().uuidString, isDirectory: true)
    try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    let invalidCharacters = CharacterSet(charactersIn: "/\\:").union(.controlCharacters)
    let filename = title.components(separatedBy: invalidCharacters)
      .filter { !$0.isEmpty }.joined(separator: "-")
      .trimmingCharacters(in: .whitespacesAndNewlines)
    let fileURL = directory.appendingPathComponent(filename.isEmpty ? "Timetable" : filename)
      .appendingPathExtension("png")
    do {
      try data.write(to: fileURL, options: .atomic)
    } catch {
      try? FileManager.default.removeItem(at: directory)
      throw error
    }

    self.image = image
    self.title = title
    self.fileURL = fileURL
    super.init()
  }

  deinit {
    try? FileManager.default.removeItem(at: fileURL.deletingLastPathComponent())
  }

  public func activityViewControllerPlaceholderItem(_ activityViewController: UIActivityViewController) -> Any {
    // UIKit uses the placeholder to discover image activities such as Save Image.
    image
  }

  public func activityViewController(
    _ activityViewController: UIActivityViewController,
    itemForActivityType activityType: UIActivity.ActivityType?
  ) -> Any? {
    if activityType == .saveToCameraRoll || activityType == InstagramStoryActivity.type {
      return image
    }
    return fileURL
  }

  public func activityViewController(
    _ activityViewController: UIActivityViewController,
    subjectForActivityType activityType: UIActivity.ActivityType?
  ) -> String {
    title
  }

  public func activityViewController(
    _ activityViewController: UIActivityViewController,
    dataTypeIdentifierForActivityType activityType: UIActivity.ActivityType?
  ) -> String {
    UTType.png.identifier
  }

  public func activityViewControllerLinkMetadata(_ activityViewController: UIActivityViewController) -> LPLinkMetadata? {
    let metadata = LPLinkMetadata()
    metadata.title = title
    metadata.imageProvider = NSItemProvider(object: image)
    metadata.iconProvider = NSItemProvider(object: image)
    return metadata
  }
}
