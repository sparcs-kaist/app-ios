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
}
