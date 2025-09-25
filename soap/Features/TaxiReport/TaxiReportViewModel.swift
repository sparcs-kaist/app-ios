//
//  TaxiReportViewModel.swift
//  soap
//
//  Created by 김민찬 on 8/11/25.
//

import Foundation
import Observation
import Factory

@MainActor
@Observable
class TaxiReportViewModel {
  // MARK: - View Properties
  var selectedUser: TaxiParticipant?
  var selectedReason: TaxiReport.Reason?
  var etcDetails: String = ""
  let maxEtcDetailsLength = 30 // Restricted by Taxi backend
  
  // MARK: - Dependency
  @ObservationIgnored @Injected(\.taxiReportRepository) private var taxiReportRepository: TaxiReportRepositoryProtocol
  
  // MARK: - Functions
  public func createReport(roomID: String) async throws {
    logger.debug("[TaxiReportViewModel] creating a report")
    
    guard let selectedUser = selectedUser, let selectedReason = selectedReason else { return }
    let etcDetails = selectedReason == .etcReason ? etcDetails : ""
    
    let requestModel = TaxiCreateReport(
      reportedID: selectedUser.id,
      reason: selectedReason,
      etcDetails: etcDetails,
      time: Date(),
      roomID: roomID
    )
    
    let _ = try await taxiReportRepository.createReport(with: requestModel)
  }
}
