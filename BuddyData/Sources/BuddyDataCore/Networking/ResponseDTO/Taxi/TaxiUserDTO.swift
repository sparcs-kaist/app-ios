//
//  TaxiUserDTO.swift
//  soap
//
//  Created by Soongyu Kwon on 14/07/2025.
//

import Foundation
import BuddyDomain

struct TaxiUserDTO: Codable {
  let id: String
  let oid: String
  let name: String
  let nickname: String
  let phoneNumber: String?
  let email: String
  let withdraw: Bool
  let ban: Bool
  let agreeOnTermsOfService: Bool
  let joinAt: String
  let profileImageURL: String
  let account: String

  enum CodingKeys: String, CodingKey {
    case id
    case oid
    case name
    case nickname
    case phoneNumber
    case email
    case withdraw
    case ban
    case agreeOnTermsOfService
    case joinAt = "joinat"
    case profileImageURL = "profileImgUrl"
    case account
  }
}

extension TaxiUserDTO {
  func toModel() -> TaxiUser {
    TaxiUser(
      id: id,
      oid: oid,
      name: name,
      nickname: nickname,
      phoneNumber: phoneNumber,
      email: email,
      withdraw: withdraw,
      ban: ban,
      agreeOnTermsOfService: agreeOnTermsOfService,
      joinedAt: joinAt.toDate() ?? Date(),
      profileImageURL: URL(string: profileImageURL),
      account: account
    )
  }
}
