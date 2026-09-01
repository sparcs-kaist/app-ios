//
//  Event.swift
//  BuddyDomain
//
//  Created by Soongyu Kwon on 08/02/2026.
//

import Foundation

public protocol Event {
  var source: String { get }
  var name: String { get }
  var parameters: [String: Any] { get }
}
