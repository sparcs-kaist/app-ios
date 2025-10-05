//
//  SignInResponse.swift
//  BuddyDomain
//
//  Created by Soongyu Kwon on 05/10/2025.
//

import Foundation

public struct SignInResponse: Sendable {
  public let accessToken: String
  public let refreshToken: String
  public let ssoInfo: String

  public init(accessToken: String, refreshToken: String, ssoInfo: String) {
    self.accessToken = accessToken
    self.refreshToken = refreshToken
    self.ssoInfo = ssoInfo
  }
}
