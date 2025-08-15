//
//  TaxiReportDetailViewModel.swift
//  soap
//
//  Created by 하정우 on 8/14/25.
//

import Foundation
import Factory

@MainActor
protocol TaxiReportListViewModelProtocol: Observable {
  var state: TaxiReportListViewModel.ViewState { get set }
  var reports: (reported: [TaxiReport], reporting: [TaxiReport]) { get set }
  
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
  var reports: (reported: [TaxiReport], reporting: [TaxiReport]) = (reported: [], reporting: [])
  
  // MARK: - Dependencies
  @ObservationIgnored @Injected(\.userUseCase) private var userUseCase: UserUseCaseProtocol
  
  // MARK: - Functions
  func fetchReports() async {
    do {
      reports = try await userUseCase.fetchTaxiReports()
      state = .loaded
    } catch {
      logger.debug(error)
      state = .error(message: error.localizedDescription)
    }
  }
}
