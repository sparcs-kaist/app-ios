import Foundation
import JavaScriptKit

enum BridgeJSON {
  static func encode<T: Encodable>(
    _ value: T,
    failureMessage: String
  ) throws(JSException) -> String {
    do {
      let encoder = JSONEncoder()
      encoder.outputFormatting = [.sortedKeys]
      return String(decoding: try encoder.encode(value), as: UTF8.self)
    } catch {
      throw BridgeJSON.error(failureMessage)
    }
  }

  static func error(_ message: String) -> JSException {
    JSException(message: message)
  }
}
