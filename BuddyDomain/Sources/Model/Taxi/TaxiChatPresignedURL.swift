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
  public let fields: [String: String]

  public init(id: String, url: String, fields: [String : String]) {
    self.id = id
    self.url = url
    self.fields = fields
  }
}
