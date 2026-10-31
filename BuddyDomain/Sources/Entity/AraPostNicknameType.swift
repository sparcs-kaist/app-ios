//
//  AraPostNicknameType.swift
//  soap
//
//  Created by Soongyu Kwon on 10/08/2025.
//

import Foundation

public enum AraPostNicknameType: String, Sendable {
  case anonymous = "ANONYMOUS"
  case regular = "REGULAR"
  case realName = "REALNAME"

  /// Ara's numeric `name_type` in responses (flags: regular 1, anonymous 2, real name 4).
  public init?(code: Int) {
    switch code {
    case 1: self = .regular
    case 2: self = .anonymous
    case 4: self = .realName
    default: return nil
    }
  }

  /// The types set in a board's `name_type` flags.
  public static func allowed(byFlags flags: Int) -> [AraPostNicknameType] {
    let flagged: [(flag: Int, type: AraPostNicknameType)] = [(1, .regular), (2, .anonymous), (4, .realName)]
    return flagged.filter { flags & $0.flag != 0 }.map(\.type)
  }
}
