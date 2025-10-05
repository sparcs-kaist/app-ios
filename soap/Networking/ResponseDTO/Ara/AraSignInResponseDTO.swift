//
//  AraSignInResponseDTO.swift
//  soap
//
//  Created by Soongyu Kwon on 13/08/2025.
//

import Foundation
import BuddyDomain

struct AraSignInResponseDTO: Codable {
  let uid: String
  let nickname: String
  let userID: Int

  enum CodingKeys: String, CodingKey {
    case uid
    case nickname
    case userID = "user_id"
  }
}

extension AraSignInResponseDTO {
  func toModel() -> AraSignInResponse {
    AraSignInResponse(uid: uid, nickname: nickname, userID: userID)
  }
}
