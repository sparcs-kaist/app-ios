//
//  TaxiNoticeRepository.swift
//  soap
//
//  Created by 하정우 on 8/14/25.
//

import Foundation

@preconcurrency
import Moya

protocol TaxiNoticeRepositoryProtocol: Sendable {
  func fetchNotice() async throws -> [TaxiNotice]
}

final class TaxiNoticeRepository: TaxiNoticeRepositoryProtocol {
  private let provider: MoyaProvider<TaxiNoticeTarget>
 
  init(provider: MoyaProvider<TaxiNoticeTarget>) {
    self.provider = provider
  }
  
  func fetchNotice() async throws -> [TaxiNotice] {
    let response = try await self.provider.request(.fetchNotice)
    logger.debug(response)
    let result = try response.map(TaxiNoticeDTO.self).notices.map { try $0.toModel() }
    
    return result
  }
}
