//
//  SignInResponseDTO.swift
//  soap
//
//  Created by Soongyu Kwon on 01/08/2025.
//

import Foundation
import BuddyDomain

public struct SignInResponseDTO: Codable {
  let accessToken: String
  let refreshToken: String
  let ssoInfo: String
}

public extension SignInResponseDTO {
  func toModel() -> SignInResponse {
    SignInResponse(accessToken: accessToken, refreshToken: refreshToken, ssoInfo: ssoInfo)
  }
}
