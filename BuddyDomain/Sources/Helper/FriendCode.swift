//
//  FriendCode.swift
//  BuddyDomain
//
//  Created by Soongyu Kwon on 28/09/2026.
//

import Foundation

/// Friend invite codes: six characters from the server's alphabet, which leaves out
/// look-alikes such as 0/O, 1/I and 8/B. Matches otlplus-server's `FRIEND_CODE_ALPHABET`
/// and the web's `FriendCodeSchema`.
public enum FriendCode {
  public static let length = 6
  public static let alphabet: Set<Character> = Set("ACDEFHJKLMNPQRTUVWXY3479")

  /// The code as the server expects it, or `nil` when it can't be one.
  public static func normalized(_ input: String) -> String? {
    let code = input.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
    guard code.count == length, code.allSatisfy(alphabet.contains) else { return nil }
    return code
  }

  /// What a code field keeps while the user types: upper-cased, only characters a code
  /// can hold, and no more than six, so an invalid code never reaches the field.
  public static func sanitized(_ input: String) -> String {
    String(input.uppercased().filter(alphabet.contains).prefix(length))
  }
}
