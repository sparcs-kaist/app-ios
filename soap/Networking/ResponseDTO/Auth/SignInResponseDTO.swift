//
//  SignInResponseDTO.swift
//  soap
//
//  Created by Soongyu Kwon on 01/08/2025.
//

import Foundation
import BuddyDomain

struct SignInResponseDTO: Codable {
  let accessToken: String
  let refreshToken: String
  let ssoInfo: String
}

extension SignInResponseDTO {
  func toModel() -> SignInResponse {
    SignInResponse(accessToken: accessToken, refreshToken: refreshToken, ssoInfo: ssoInfo)
  }
}
