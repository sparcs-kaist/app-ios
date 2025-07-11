//
//  TaxiInfo+Mockable.swift
//  soap
//
//  Created by Minjae Kim on 3/30/25.
//

#if DEBUG
import Foundation

extension RoomInfo: Mockable {
    static var mock: RoomInfo {
        RoomInfo(
            origin: TaxiLocationOld.mockList[0],
            destination: TaxiLocationOld.mockList[1],
            name: "레로레로레로레로",
            occupancy: 2,
            capacity: 4,
            departureTime: Date().ceilToNextTenMinutes()
        )
    }

    static var mockList: [RoomInfo] {
        [
            RoomInfo(
                origin: TaxiLocationOld.mockList[0],
                destination: TaxiLocationOld.mockList[2],
                name: "순규is바보",
                occupancy: 1,
                capacity: 3,
                departureTime: Date().addingTimeInterval(600)
            ),
            RoomInfo(
                origin: TaxiLocationOld.mockList[1],
                destination: TaxiLocationOld.mockList[4],
                name: "민재is천재",
                occupancy: 3,
                capacity: 4,
                departureTime: Date().addingTimeInterval(1200)
            )
        ]
    }
}
#endif
