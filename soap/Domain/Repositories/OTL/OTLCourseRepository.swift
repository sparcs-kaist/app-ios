//
//  OTLCourseRepository.swift
//  soap
//
//  Created by 하정우 on 10/1/25.
//

import Foundation

@preconcurrency
import Moya

protocol OTLCourseRepositoryProtocol: Sendable {
  func searchCourse(name: String, offset: Int, limit: Int) async throws -> [Course]
}

final class OTLCourseRepository: OTLCourseRepositoryProtocol, Sendable {
  private let provider: MoyaProvider<OTLCourseTarget>
  
  init(provider: MoyaProvider<OTLCourseTarget>) {
    self.provider = provider
  }
  
  func searchCourse(name: String, offset: Int, limit: Int) async throws -> [Course] {
    let response = try await self.provider.request(
      .searchCourse(name: name, offset: offset, limit: limit)
    )
    let result = try response.map([CourseDTO].self).compactMap { $0.toModel() }
    
    return result
  }
}
