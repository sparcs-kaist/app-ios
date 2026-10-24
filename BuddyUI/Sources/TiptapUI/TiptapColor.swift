import SwiftUI

/// Parses the CSS colours Tiptap's `Color` extension writes (`#rgb`, `#rrggbb`, `rgb()`/`rgba()`).
enum TiptapColor {
  /// - Parameter allowsExtremes: When `false`, near-black and near-white are ignored.
  ///   Authors pick those on the web's white page to mean "default", and honouring
  ///   them would make the text vanish in the opposite colour scheme.
  static func parse(_ css: String?, allowsExtremes: Bool = false) -> Color? {
    guard let css = css?.trimmingCharacters(in: .whitespaces).lowercased(), !css.isEmpty,
          let (red, green, blue) = components(of: css) else { return nil }

    if !allowsExtremes {
      let luminance = 0.2126 * red + 0.7152 * green + 0.0722 * blue
      guard (0.12...0.9).contains(luminance) else { return nil }
    }
    return Color(red: red, green: green, blue: blue)
  }

  private static func components(of css: String) -> (Double, Double, Double)? {
    if css.hasPrefix("#") {
      var hex = String(css.dropFirst())
      if hex.count == 3 || hex.count == 4 {
        hex = String(hex.prefix(3).flatMap { [$0, $0] })
      }
      guard hex.count >= 6, let value = UInt32(hex.prefix(6), radix: 16) else { return nil }
      return (
        Double((value >> 16) & 0xFF) / 255,
        Double((value >> 8) & 0xFF) / 255,
        Double(value & 0xFF) / 255
      )
    }

    if css.hasPrefix("rgb"), let open = css.firstIndex(of: "("), let close = css.lastIndex(of: ")") {
      let channels = css[css.index(after: open)..<close]
        .split(whereSeparator: { $0 == "," || $0 == " " || $0 == "/" })
        .prefix(3)
        .compactMap { Double($0) }
      guard channels.count == 3 else { return nil }
      return (channels[0] / 255, channels[1] / 255, channels[2] / 255)
    }
    return nil
  }
}
