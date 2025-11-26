//
//  TaxiRoom+Mockable.swift
//  soap
//
//  Created by Soongyu Kwon on 12/07/2025.
//

import Foundation
import BuddyDomain

extension TaxiRoom: Mockable { }

public extension TaxiRoom {
  static var mock: TaxiRoom {
    mockList[0]
  }

  static var mockList: [TaxiRoom] {
    let baseDate = Date().addingTimeInterval(3600)

    let locations: [TaxiLocation] = TaxiLocation.mockList

    let participants: [TaxiParticipant] = [
      .init(
        id: "686d4d8f56fd773a8bd9d78a",
        name: "tuesday-name",
        nickname: "tuesday-nickname",
        profileImageURL: URL(
          string: "https://sparcs-taxi-dev.s3.ap-northeast-2.amazonaws.com/profile-img/default/NupjukOTL.png"
        ),
        withdraw: false,
        badge: true,
        isSettlement: nil,
        readAt: baseDate
      ),
      .init(
        id: "686d4d8f56fd773a8bd9d78c",
        name: "wednesday-name",
        nickname: "wednesday-nickname",
        profileImageURL: URL(
          string: "https://sparcs-taxi-dev.s3.ap-northeast-2.amazonaws.com/profile-img/default/GooseOTL.png"
        ),
        withdraw: false,
        badge: true,
        isSettlement: nil,
        readAt: baseDate
      )
    ]

    return (0..<18).map { index in
      TaxiRoom(
        id: UUID().uuidString,
        title: "Mock Room \(index + 1)",
        source: locations[index % locations.count],
        destination: locations[(index + 3) % locations.count],
        departAt: Calendar.current.date(byAdding: .day, value: index % 7, to: baseDate)!,
        participants: participants,
        madeAt: baseDate,
        capacity: 4,
        settlementTotal: nil,
        isDeparted: false,
        isOver: nil
      )
    }
  }
}
