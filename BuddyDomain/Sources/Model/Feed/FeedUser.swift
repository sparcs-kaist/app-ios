//
//  FeedUser.swift
//  soap
//
//  Created by Soongyu Kwon on 20/08/2025.
//

import Foundation

public struct FeedUser: Identifiable, Hashable, Sendable {
  public let id: String
  public let nickname: String
  public let profileImageURL: URL?
  public let karma: Int

  public init(id: String, nickname: String, profileImageURL: URL?, karma: Int) {
    self.id = id
    self.nickname = nickname
    self.profileImageURL = profileImageURL
    self.karma = karma
  }
}

