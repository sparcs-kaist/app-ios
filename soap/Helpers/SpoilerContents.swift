//
//  SpoilerContents.swift
//  soap
//
//  Created by 하정우 on 10/2/25.
//

import Foundation

@Observable
class SpoilerContents {
  private var items: Set<String> = []
  
  func add(_ item: String) {
    items.insert(item)
  }
  
  func remove(_ item: String) {
    items.remove(item)
  }
  
  func contains(_ item: String) -> Bool {
    items.contains(item)
  }
}
