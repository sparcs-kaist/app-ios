//
//  AuthPlugin.swift
//  soap
//
//  Created by Soongyu Kwon on 09/07/2025.
//

import Foundation
import Moya

final class AuthPlugin: PluginType {
  private let tokenStorage: TokenStorageProtocol

  init(tokenStorage: TokenStorageProtocol) {
    self.tokenStorage = tokenStorage
  }

  func prepare(_ request: URLRequest, target: any TargetType) -> URLRequest {
    var request = request

    if let accessToken = tokenStorage.getAccessToken() {
      request.addValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
    }

    return request
  }
}
