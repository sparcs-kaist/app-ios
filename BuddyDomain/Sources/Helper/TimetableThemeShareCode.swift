import Foundation

public enum TimetableThemeShareCode {
  public static func normalized(_ input: String) -> String? {
    let code = input.trimmingCharacters(in: .whitespacesAndNewlines)
    guard code.utf8.count == 6,
          code.utf8.allSatisfy({ (48...57).contains($0) || (65...90).contains($0) || (97...122).contains($0) }) else {
      return nil
    }
    return code.uppercased()
  }
}
