//
//  SignInResponseDTO.swift
//  soap
//
//  Created by Soongyu Kwon on 01/08/2025.
//

import Foundation

struct SignInResponseDTO: Codable {
  let accessToken: String
  let refreshToken: String
  let ssoInfo: String
}
