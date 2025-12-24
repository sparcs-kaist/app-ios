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
