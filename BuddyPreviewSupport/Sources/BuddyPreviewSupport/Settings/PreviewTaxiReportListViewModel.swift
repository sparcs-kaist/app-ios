//
//  PreviewTaxiReportListViewModel.swift
//  BuddyPreviewSupport
//
//  Created by 하정우 on 5/13/2026.
//

import Observation
import BuddyDomain

@Observable
@MainActor
public final class PreviewTaxiReportListViewModel: TaxiReportListViewModelProtocol {
  public var state: TaxiReportListViewState
  public var reports: (incoming: [TaxiReport], outgoing: [TaxiReport])

  public init(state: TaxiReportListViewState = .loaded) {
    self.state = state
    self.reports = (incoming: TaxiReport.mockList, outgoing: TaxiReport.mockList)
  }

  public func fetchReports() async {}
}
