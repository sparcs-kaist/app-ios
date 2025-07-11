//
//  Collection+Extensions.swift
//  soap
//
//  Created by Soongyu Kwon on 29/06/2025.
//

import Foundation

extension Collection {
  subscript(safe index: Index) -> Element? {
    return indices.contains(index) ? self[index] : nil
  }
}
