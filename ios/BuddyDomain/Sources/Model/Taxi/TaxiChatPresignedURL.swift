//
//  TaxiChatPresignedURL.swift
//  BuddyDomain
//
//  Created by Soongyu Kwon on 05/10/2025.
//

import Foundation

public struct TaxiChatPresignedURL: Sendable {
  public let id: String
  public let url: String

  public init(id: String, url: String) {
    self.id = id
    self.url = url
  }
}
