//
//  Character+Extensions.swift
//  soap
//
//  Created by 하정우 on 12/29/25.
//

import Foundation

public extension Character {
  /// A Boolean value indicating whether this is an ASCII number(0-9).
  var isASCIINumber: Bool {
    self.isASCII && self.isNumber
  }
}
