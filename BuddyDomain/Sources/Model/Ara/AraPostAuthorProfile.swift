//
//  AraPostAuthorProfile.swift
//  soap
//
//  Created by Soongyu Kwon on 06/08/2025.
//

import Foundation

public struct AraPostAuthorProfile: Identifiable, Hashable, Sendable {
  public let id: String
  public let profilePictureURL: URL?
  public let nickname: String
  public let isOfficial: Bool?
  public let isSchoolAdmin: Bool?

  public init(
    id: String,
    profilePictureURL: URL?,
    nickname: String,
    isOfficial: Bool?,
    isSchoolAdmin: Bool?
  ) {
    self.id = id
    self.profilePictureURL = profilePictureURL
    self.nickname = nickname
    self.isOfficial = isOfficial
    self.isSchoolAdmin = isSchoolAdmin
  }
}
