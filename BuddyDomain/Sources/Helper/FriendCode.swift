//
//  FriendCode.swift
//  BuddyDomain
//
//  Created by Soongyu Kwon on 28/09/2026.
//

import Foundation

/// Friend invite codes are six ASCII letters/digits, upper-cased — the same
/// shape as timetable theme share codes.
public enum FriendCode {
  public static func normalized(_ input: String) -> String? {
    let code = input.trimmingCharacters(in: .whitespacesAndNewlines)
    guard code.utf8.count == 6,
          code.utf8.allSatisfy({ (48...57).contains($0) || (65...90).contains($0) || (97...122).contains($0) }) else {
      return nil
    }
    return code.uppercased()
  }
}
