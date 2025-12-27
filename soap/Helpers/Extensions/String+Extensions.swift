//
//  String+Extensions.swift
//  soap
//
//  Created by Soongyu Kwon on 04/01/2025.
//

import Foundation

extension String {
  var urlEscaped: String {
    addingPercentEncoding(withAllowedCharacters: .urlHostAllowed)!
  }
  
  func formatPhoneNumber() -> String {
    /// Formats the string as a Korean phone number in the form `XXX-XXXX-XXXX`.
    ///
    /// This method extracts only numeric characters from the receiver and then
    /// applies the `XXX-XXXX-XXXX` mask. It is intended for 11-digit Korean
    /// mobile numbers (including the leading `0`), but will format as many
    /// digits as are available, left to right, ignoring any non-digit characters.
    ///
    /// - Returns: A string containing the extracted digits formatted according
    ///   to the `XXX-XXXX-XXXX` pattern.

    let cleanNumber = self.filter { $0.isNumber }
    
    let mask = "XXX-XXXX-XXXX"
    
    var result = ""
    var startIndex = cleanNumber.startIndex
    let endIndex = cleanNumber.endIndex
    
    for char in mask where startIndex < endIndex {
      if char == "X" {
        result.append(cleanNumber[startIndex])
        startIndex = cleanNumber.index(after: startIndex)
      } else {
        result.append(char)
      }
    }
    
    return result
  }
}
