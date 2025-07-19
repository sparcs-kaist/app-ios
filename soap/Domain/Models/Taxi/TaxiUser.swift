//
//  TaxiUser.swift
//  soap
//
//  Created by Soongyu Kwon on 14/07/2025.
//

import Foundation

public struct TaxiUser: Identifiable, Hashable, Sendable {
  public let id: String
  let oid: String
  let name: String
  let nickname: String
  let phoneNumber: String?
  let email: String
  let withdraw: Bool
  let ban: Bool
  let agreeOnTermsOfService: Bool
  let joinedAt: Date
  let profileImageURL: URL?
  let account: String
}
