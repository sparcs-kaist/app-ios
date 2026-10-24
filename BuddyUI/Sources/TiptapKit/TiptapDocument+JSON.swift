import Foundation

extension TiptapDocument {
  /// Serialises the document as a Tiptap `doc`, the shape the Ara web editor stores.
  ///
  /// With `sanitizerSafe` (the default), `&`, `<`, `>`, `.` and `/` inside strings are
  /// written as `\u` escapes. JSON parsers read them back unchanged, but an HTML sanitiser
  /// run over the raw string — as the Ara server does with bleach — then finds no entities
  /// to escape and no URLs or domains to linkify, so the stored JSON stays valid.
  public func jsonString(sanitizerSafe: Bool = true) -> String {
    var writer = TiptapJSONWriter(sanitizerSafe: sanitizerSafe)
    writer.write(TiptapNode(type: .doc, content: content))
    return writer.output
  }
}

private struct TiptapJSONWriter {
  let sanitizerSafe: Bool
  var output = ""

  /// Entity-escaped by an HTML sanitiser (`&`, `<`, `>`) or part of what a linkifier matches (`.`, `/`).
  private static let sanitizerSensitive: Set<Unicode.Scalar> = ["&", "<", ">", ".", "/"]

  init(sanitizerSafe: Bool) {
    self.sanitizerSafe = sanitizerSafe
  }

  mutating func write(_ node: TiptapNode) {
    output += "{\"type\":"
    writeString(node.type.rawValue)
    if !node.attrs.isEmpty {
      output += ",\"attrs\":"
      writeObject(node.attrs)
    }
    if !node.content.isEmpty {
      output += ",\"content\":["
      for (index, child) in node.content.enumerated() {
        if index > 0 { output += "," }
        write(child)
      }
      output += "]"
    }
    if !node.marks.isEmpty {
      output += ",\"marks\":["
      for (index, mark) in node.marks.enumerated() {
        if index > 0 { output += "," }
        output += "{\"type\":"
        writeString(mark.type.rawValue)
        if !mark.attrs.isEmpty {
          output += ",\"attrs\":"
          writeObject(mark.attrs)
        }
        output += "}"
      }
      output += "]"
    }
    if let text = node.text {
      output += ",\"text\":"
      writeString(text)
    }
    output += "}"
  }

  private mutating func writeObject(_ object: [String: TiptapValue]) {
    output += "{"
    // Sorted so the same document always serialises the same way.
    for (index, key) in object.keys.sorted().enumerated() {
      if index > 0 { output += "," }
      writeString(key)
      output += ":"
      writeValue(object[key]!)
    }
    output += "}"
  }

  private mutating func writeValue(_ value: TiptapValue) {
    switch value {
    case .string(let string):
      writeString(string)
    case .number(let number):
      output += number.rounded() == number && abs(number) < 1e15 ? String(Int(number)) : String(number)
    case .bool(let bool):
      output += bool ? "true" : "false"
    case .null:
      output += "null"
    case .array(let array):
      output += "["
      for (index, element) in array.enumerated() {
        if index > 0 { output += "," }
        writeValue(element)
      }
      output += "]"
    case .object(let object):
      writeObject(object)
    }
  }

  private mutating func writeString(_ string: String) {
    output += "\""
    for scalar in string.unicodeScalars {
      switch scalar {
      case "\"": output += "\\\""
      case "\\": output += "\\\\"
      case "\n": output += "\\n"
      case "\r": output += "\\r"
      case "\t": output += "\\t"
      default:
        if scalar.value < 0x20 || (sanitizerSafe && Self.sanitizerSensitive.contains(scalar)) {
          output += String(format: "\\u%04X", scalar.value)
        } else {
          output.unicodeScalars.append(scalar)
        }
      }
    }
    output += "\""
  }
}
