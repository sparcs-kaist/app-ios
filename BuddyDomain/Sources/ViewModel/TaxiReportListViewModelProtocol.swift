//
//  TaxiReportListViewModelProtocol.swift
//  BuddyDomain
//
//  Created by 하정우 on 5/13/2026.
//

import Observation

@MainActor
public protocol TaxiReportListViewModelProtocol: Observable {
  var state: TaxiReportListViewState { get set }
  var reports: (incoming: [TaxiReport], outgoing: [TaxiReport]) { get set }

  func fetchReports() async
}
