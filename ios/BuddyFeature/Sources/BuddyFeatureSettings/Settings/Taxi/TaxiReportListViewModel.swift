//
//  TaxiReportDetailViewModel.swift
//  soap
//
//  Created by 하정우 on 8/14/25.
//

import Foundation
import Factory
import BuddyDomain
import os

private let logger = Logger(subsystem: "org.sparcs.soap", category: "TaxiReportListViewModel")

/// Equatable wrapper for the incoming/outgoing report lists. A tuple can't
/// conform to Equatable, so the @Observable setter couldn't skip redundant
/// invalidations when the same reports were fetched again.
struct TaxiReports: Equatable {
  var incoming: [TaxiReport]
  var outgoing: [TaxiReport]
}

@MainActor
protocol TaxiReportListViewModelProtocol: Observable {
  var state: TaxiReportListViewModel.ViewState { get set }
  var reports: TaxiReports { get set }

  func fetchReports() async
}

@MainActor
class TaxiReportListViewModel: TaxiReportListViewModelProtocol, Observable {
  enum ViewState: Equatable {
    case loading
    case loaded
    case error(message: String)
  }
  
  // MARK: - Properties
  var state: ViewState = .loading
  var reports: TaxiReports = TaxiReports(incoming: [], outgoing: [])
  
  // MARK: - Dependencies
  @ObservationIgnored @Injected(\.taxiReportRepository) private var taxiReportRepository: TaxiReportRepositoryProtocol?

  // MARK: - Functions
  func fetchReports() async {
    guard let taxiReportRepository else { return }

    do {
      let fetched = try await taxiReportRepository.fetchMyReports()
      reports = TaxiReports(incoming: fetched.incoming, outgoing: fetched.outgoing)
      state = .loaded
    } catch {
      logger.error("Failed to fetch reports: \(error.localizedDescription, privacy: .public)")
      state = .error(message: error.localizedDescription)
    }
  }
}
