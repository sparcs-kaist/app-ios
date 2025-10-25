//
//  TaxiReportRepository.swift
//  soap
//
//  Created by 김민찬 on 8/11/25.
//

import Foundation
import Moya
import BuddyDomain

public final class TaxiReportRepository: TaxiReportRepositoryProtocol, @unchecked Sendable {
  private let provider: MoyaProvider<TaxiReportTarget>
  
  public init(provider: MoyaProvider<TaxiReportTarget>) {
    self.provider = provider
  }
  
  public func fetchMyReports() async throws -> (incoming: [TaxiReport], outgoing: [TaxiReport]) {
    do {
      let response = try await provider.request(.fetchMyReports)
      let result = try response.map(TaxiMyReportsResponseDTO.self)
      
      let incomingReports: [TaxiReport] = result.incoming.compactMap { $0.toModel() }
      let outgoingReports: [TaxiReport] = result.outgoing.compactMap { $0.toModel() }
      
      return (incoming: incomingReports, outgoing: outgoingReports)
    } catch let moyaError as MoyaError {
      let body = try moyaError.response!.map(APIErrorResponse.self)
      throw body
    } catch {
      throw error
    }
  }
  
  public func createReport(with: TaxiCreateReport) async throws {
    let requestDTO = TaxiCreateReportRequestDTO.fromModel(with)
    let response = try await provider.request(.createReport(with: requestDTO))
    _ = try response.filterSuccessfulStatusCodes()
  }
}
