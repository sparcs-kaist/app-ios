//
//  AlertState.swift
//  BuddyDomain
//
//  Created by Soongyu Kwon on 04/02/2026.
//

import SwiftUI

public struct AlertState: Identifiable {
  public let id = UUID()
  public let title: String
  public let message: String

  public init(title: String, message: String) {
    self.title = title
    self.message = message
  }
}

