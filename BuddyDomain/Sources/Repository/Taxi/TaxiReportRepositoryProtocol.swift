//
//  TaxiReportRepositoryProtocol.swift
//  BuddyDomain
//
//  Created by Soongyu Kwon on 05/10/2025.
//

import Foundation

public protocol TaxiReportRepositoryProtocol: Sendable {
  func fetchMyReports() async throws -> (incoming: [TaxiReport], outgoing: [TaxiReport])
  func createReport(with: TaxiCreateReport) async throws
}
