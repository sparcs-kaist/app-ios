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
protocol TaxiReportListViewModelProtocol: Observable {
  var state: TaxiReportListViewModel.ViewState { get set }
  var reports: (incoming: [TaxiReport], outgoing: [TaxiReport]) { get set }
  
  func fetchReports() async
}

@MainActor
class TaxiReportListViewModel: TaxiReportListViewModelProtocol, Observable {
  enum ViewState {
    case loading
    case loaded
    case error(message: String)
  }
  
  // MARK: - Properties
  var state: ViewState = .loading
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
      logger.debug(error)
      state = .error(message: error.localizedDescription)
    }
  }
}
