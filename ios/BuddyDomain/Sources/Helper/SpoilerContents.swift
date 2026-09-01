//
//  SpoilerContents.swift
//  soap
//
//  Created by 하정우 on 10/2/25.
//

import Foundation

@Observable
public class SpoilerContents {
  private var items: Set<String> = []

  public init() { }

  public func add(_ item: String) {
    items.insert(item)
  }
  
  public func remove(_ item: String) {
    items.remove(item)
  }
  
  public func contains(_ item: String) -> Bool {
    items.contains(item)
  }
}
