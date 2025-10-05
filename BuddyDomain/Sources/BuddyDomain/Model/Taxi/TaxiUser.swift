//
//  TaxiUser.swift
//  soap
//
//  Created by Soongyu Kwon on 14/07/2025.
//

import Foundation

public struct TaxiUser: Identifiable, Hashable, Sendable {
  public let id: String
  public let oid: String
  public let name: String
  public let nickname: String
  public let phoneNumber: String?
  public let email: String
  public let withdraw: Bool
  public let ban: Bool
  public let agreeOnTermsOfService: Bool
  public let joinedAt: Date
  public let profileImageURL: URL?
  public let account: String

  public init(
    id: String,
    oid: String,
    name: String,
    nickname: String,
    phoneNumber: String?,
    email: String,
    withdraw: Bool,
    ban: Bool,
    agreeOnTermsOfService: Bool,
    joinedAt: Date,
    profileImageURL: URL?,
    account: String
  ) {
    self.id = id
    self.oid = oid
    self.name = name
    self.nickname = nickname
    self.phoneNumber = phoneNumber
    self.email = email
    self.withdraw = withdraw
    self.ban = ban
    self.agreeOnTermsOfService = agreeOnTermsOfService
    self.joinedAt = joinedAt
    self.profileImageURL = profileImageURL
    self.account = account
  }
}
