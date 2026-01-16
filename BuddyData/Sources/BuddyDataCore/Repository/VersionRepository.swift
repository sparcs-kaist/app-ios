//
//  VersionRepository.swift
//  BuddyData
//
//  Created by 하정우 on 1/16/26.
//

import Foundation
import BuddyDomain

@preconcurrency
import Moya

public final class VersionRepository: VersionRepositoryProtocol {
  private let provider: MoyaProvider<VersionTarget>
  
  public init(provider: MoyaProvider<VersionTarget>) {
    self.provider = provider
  }
  
  public func getMinimumVersion() async throws -> String {
    let response = try await self.provider.request(.getMinimumVersion)
    let result = try response.map(VersionResponse.self)
    
    return result.ios
  }
}
