//
//  AuthConfiguration.swift
//  BuddyCore
//
//  Created by Soongyu Kwon on 28/03/2026.
//

import Foundation

public struct AuthConfiguration: Sendable {
  public let baseURL: URL
  public let oauthStartURL: URL
  public let callbackScheme: String
  public let callbackHost: String
  public let refreshThreshold: TimeInterval
  public let codeVerifier: String = UUID().uuidString.replacingOccurrences(of: "-", with: "")

  public init(
    baseURL: URL,
    oauthStartURL: URL,
    callbackScheme: String,
    callbackHost: String,
    refreshThreshold: TimeInterval
  ) {
    self.baseURL = baseURL
    self.oauthStartURL = oauthStartURL
    self.callbackScheme = callbackScheme
    self.callbackHost = callbackHost
    self.refreshThreshold = refreshThreshold
  }
}
