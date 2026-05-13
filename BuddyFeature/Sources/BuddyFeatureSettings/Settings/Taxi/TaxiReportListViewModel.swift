//
//  TaxiReportDetailViewModel.swift
//  soap
//
//  Created by 하정우 on 8/14/25.
//

import Foundation
import Factory
import BuddyDomain

@MainActor
class TaxiReportListViewModel: TaxiReportListViewModelProtocol, Observable {
  // MARK: - Properties
  var state: TaxiReportListViewState = .loading
  var reports: (incoming: [TaxiReport], outgoing: [TaxiReport]) = (incoming: [], outgoing: [])
  
  // MARK: - Dependencies
  @ObservationIgnored @Injected(\.taxiReportRepository) private var taxiReportRepository: TaxiReportRepositoryProtocol?

  // MARK: - Functions
  func fetchReports() async {
    guard let taxiReportRepository else { return }

    do {
      reports = try await taxiReportRepository.fetchMyReports()
      state = .loaded
    } catch {
      state = .error(message: error.localizedDescription)
    }
  }
}
