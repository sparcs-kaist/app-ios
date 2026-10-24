import Foundation

/// An arbitrary JSON value, used for node and mark attributes.
public enum TiptapValue: Sendable, Hashable {
  case string(String)
  case number(Double)
  case bool(Bool)
  case array([TiptapValue])
  case object([String: TiptapValue])
  case null

  public var stringValue: String? {
    switch self {
    case .string(let value): value
    case .number(let value): value.rounded() == value ? String(Int(value)) : String(value)
    case .bool(let value): String(value)
    default: nil
    }
  }

  /// Accepts numbers and numeric strings alike; editors aren't consistent about which they write.
  public var doubleValue: Double? {
    switch self {
    case .number(let value): value
    case .string(let value): Double(value.trimmingCharacters(in: .whitespaces))
    default: nil
    }
  }

  public var intValue: Int? {
    doubleValue.flatMap { $0.isFinite ? Int($0) : nil }
  }

  public var boolValue: Bool? {
    switch self {
    case .bool(let value): value
    case .string(let value): Bool(value)
    default: nil
    }
  }
}

extension TiptapValue: Decodable {
  public init(from decoder: any Decoder) throws {
    let container = try decoder.singleValueContainer()
    if container.decodeNil() {
      self = .null
    } else if let value = try? container.decode(Bool.self) {
      self = .bool(value)
    } else if let value = try? container.decode(Double.self) {
      self = .number(value)
    } else if let value = try? container.decode(String.self) {
      self = .string(value)
    } else if let value = try? container.decode([TiptapValue].self) {
      self = .array(value)
    } else {
      self = .object(try container.decode([String: TiptapValue].self))
    }
  }
}
