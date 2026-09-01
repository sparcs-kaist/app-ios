//
//  AraSignInResponse.swift
//  BuddyDomain
//
//  Created by Soongyu Kwon on 05/10/2025.
//

import Foundation

public struct AraSignInResponse: Sendable {
  public let uid: String
  public let nickname: String
  public let userID: Int

  public init(uid: String, nickname: String, userID: Int) {
    self.uid = uid
    self.nickname = nickname
    self.userID = userID
  }
}
