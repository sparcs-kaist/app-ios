import Foundation

/// A small, allocation-light HTML entity decoder covering what sanitisers emit:
/// the XML entities, `&nbsp;` and numeric character references.
enum HTMLEntities {
  private static let named: [Substring: Character] = [
    "amp": "&",
    "lt": "<",
    "gt": ">",
    "quot": "\"",
    "apos": "'",
    "nbsp": "\u{00A0}",
  ]

  /// The longest reference handled, `&#x10FFFF;`, is ten characters.
  private static let maxReferenceLength = 10

  static func decode(_ string: String) -> String {
    guard string.contains("&") else { return string }

    var result = ""
    result.reserveCapacity(string.utf8.count)
    var index = string.startIndex
    while index < string.endIndex {
      let character = string[index]
      if character == "&",
         let semicolon = string[index...].prefix(maxReferenceLength).firstIndex(of: ";"),
         let decoded = decodeReference(string[string.index(after: index)..<semicolon]) {
        result.append(decoded)
        index = string.index(after: semicolon)
      } else {
        result.append(character)
        index = string.index(after: index)
      }
    }
    return result
  }

  private static func decodeReference(_ name: Substring) -> Character? {
    if let character = named[name] {
      return character
    }
    guard name.first == "#" else { return nil }

    let digits = name.dropFirst()
    let scalarValue: UInt32? = if digits.first == "x" || digits.first == "X" {
      UInt32(digits.dropFirst(), radix: 16)
    } else {
      UInt32(digits, radix: 10)
    }
    return scalarValue.flatMap(Unicode.Scalar.init).map(Character.init)
  }
}
