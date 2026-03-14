//
//  OTLDepartmentRepository.swift
//  BuddyData
//
//  Created by Soongyu Kwon on 14/03/2026.
//

import Foundation
import BuddyDomain

@preconcurrency
import Moya

public final class OTLDepartmentRepository: OTLDepartmentRepositoryProtocol, Sendable {
  private let provider: MoyaProvider<OTLDepartmentTarget>

  public init(provider: MoyaProvider<OTLDepartmentTarget>) {
    self.provider = provider
  }

  public func getDepartments() async throws -> [Department] {
    let response = try await self.provider.request(.fetchDepartments)

    return try response.map(DepartmentPageDTO.self).departments.compactMap { $0.toModel() }
  }
}
