#if os(iOS)
import UIKit

extension NSAttributedString.Key {
  /// The ``TiptapBlockStyle`` raw value of the paragraph a character belongs to.
  public static let tiptapBlockStyle = NSAttributedString.Key("TiptapBlockStyle")
}

/// The paragraph styles the editor offers, which are the text blocks Ara's editor can store.
///
/// They're offered as the formatting panel's styles (Title, Heading, …), as in Notes.
public enum TiptapBlockStyle: String, CaseIterable, Sendable {
  case title
  case heading
  case subheading
  case body
  case monospaced

  /// The Tiptap `heading` level, or `nil` for a paragraph or code block.
  var headingLevel: Int? {
    switch self {
    case .title: 1
    case .heading: 2
    case .subheading: 3
    case .body, .monospaced: nil
    }
  }

  var localizedTitle: LocalizedStringResource {
    let bundle = LocalizedStringResource.BundleDescription.atURL(Bundle.module.bundleURL)
    return switch self {
    case .title: LocalizedStringResource("Title", bundle: bundle)
    case .heading: LocalizedStringResource("Heading", bundle: bundle)
    case .subheading: LocalizedStringResource("Subheading", bundle: bundle)
    case .body: LocalizedStringResource("Body", bundle: bundle)
    case .monospaced: LocalizedStringResource("Monospaced", bundle: bundle)
    }
  }

  /// Plain system fonts at the current Dynamic Type sizes. Not scaled with `UIFontMetrics`:
  /// the formatting panel scales each style's font for its preview, and UIKit throws when a
  /// font has been scaled already.
  var font: UIFont {
    switch self {
    case .title: Self.font(.title1, weight: .bold)
    case .heading: Self.font(.title2, weight: .bold)
    case .subheading: Self.font(.title3, weight: .semibold)
    case .body: Self.font(.body, weight: .regular)
    case .monospaced:
      .monospacedSystemFont(ofSize: UIFont.preferredFont(forTextStyle: .callout).pointSize, weight: .regular)
    }
  }

  /// The attributes a paragraph in this style is typed with.
  var attributes: [NSAttributedString.Key: Any] {
    [
      .font: font,
      .foregroundColor: UIColor.label,
      .tiptapBlockStyle: rawValue,
    ]
  }

  private static func font(_ style: UIFont.TextStyle, weight: UIFont.Weight) -> UIFont {
    .systemFont(ofSize: UIFont.preferredFont(forTextStyle: style).pointSize, weight: weight)
  }

  /// The paragraph's style: its tag when it has one, otherwise inferred from its font, so text
  /// pasted in or restyled by Writing Tools still maps sensibly.
  static func of(_ attributes: [NSAttributedString.Key: Any]) -> TiptapBlockStyle {
    if let raw = attributes[.tiptapBlockStyle] as? String, let style = TiptapBlockStyle(rawValue: raw) {
      return style
    }
    guard let font = attributes[.font] as? UIFont else { return .body }
    let bodySize = TiptapBlockStyle.body.font.pointSize
    switch font.pointSize {
    case (TiptapBlockStyle.title.font.pointSize - 0.5)...: return .title
    case (TiptapBlockStyle.heading.font.pointSize - 0.5)...: return .heading
    case (TiptapBlockStyle.subheading.font.pointSize - 0.5)... where font.pointSize > bodySize: return .subheading
    default: return .body
    }
  }
}

extension UITextFormattingViewController.Configuration {
  /// Notes' formatting panel, limited to what a Tiptap post can store: styles, bold / italic /
  /// underline / strikethrough, lists and text colour. No fonts, sizes, alignment or highlight.
  @MainActor
  static var tiptap: UITextFormattingViewController.Configuration {
    let configuration = UITextFormattingViewController.Configuration(groups: [
      .group([.component(.formattingStyles, .automatic)]),
      .group([.component(.fontAttributes, .automatic)]),
      .group([
        .component(.listStyles, .automatic),
        .component(.textColor, .automatic),
      ]),
    ])
    configuration.formattingStyles = TiptapBlockStyle.allCases.map { style in
      UITextFormattingViewController.FormattingStyle(
        styleKey: style.rawValue,
        title: style.localizedTitle,
        attributes: style.attributes
      )
    }
    return configuration
  }
}
#endif
