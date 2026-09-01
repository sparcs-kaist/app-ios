//
//  Data+Extensions.swift
//  soap
//
//  Created by Soongyu Kwon on 10/07/2025.
//

import Foundation
import CryptoKit

extension Data {
  func sha256() -> Data {
    let hash = SHA256.hash(data: self)
    return Data(hash)
  }

  func base64URLEncodedString() -> String {
    return self.base64EncodedString()
      .replacingOccurrences(of: "+", with: "-")
      .replacingOccurrences(of: "/", with: "_")
      .replacingOccurrences(of: "=", with: "")
  }
}
