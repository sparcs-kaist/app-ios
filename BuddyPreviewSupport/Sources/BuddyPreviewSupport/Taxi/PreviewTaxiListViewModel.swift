//
//  PreviewTaxiListViewModel.swift
//  BuddyPreviewSupport
//
//  Created by 하정우 on 3/6/26.
//

import Foundation
import BuddyDomain

@MainActor
@Observable
public class PreviewTaxiListViewModel: TaxiListViewModelProtocol {
  public var state: TaxiListViewState
  public var rooms: [TaxiRoom] = TaxiRoom.mockList
  public var source: TaxiLocation?
  public var destination: TaxiLocation?
  public var selectedDate: Date = Date()
  public var roomDepartureTime: Date = Date().ceilToNextTenMinutes()
  public var roomCapacity: Int = 4
  
  public var locations: [TaxiLocation] = [
    .init(
      id: UUID().uuidString,
      title: LocalizedString(["ko": "대전역", "en": "Daejeon Station"]),
      priority: 0.0,
      latitude: 36.3319731,
      longitude: 127.4323382
    ),
    .init(
      id: UUID().uuidString,
      title: LocalizedString(["ko": "카이스트 본원", "en": "KAIST Main Campus"]),
      priority: 0.0,
      latitude: 36.3723596,
      longitude: 127.358697
    )
  ]
  
  public var week: [Date] {
    let calendar = Calendar.current
    return (0..<7).compactMap {
      calendar.date(byAdding: .day, value: $0, to: Date())
    }
  }
  
  public init(state: TaxiListViewState) {
    self.state = state
  }
  
  public func fetchData() async { }
  public func createRoom(title: String) async throws { }
}
