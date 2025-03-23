//
//  TaxiLocation+Mockable.swift
//  soap
//
//  Created by Soongyu Kwon on 23/03/2025.
//

import Foundation
import MapKit

#if DEBUG
extension TaxiLocation: Mockable {
  static var mock: TaxiLocation {
    TaxiLocation(
      id: "636c70c308eab94199a3cbff",
      title: "KAIST Main Campus",
      priority: 0,
      latitude: 36.3723596,
      longitude: 127.358697
    )
  }

  static var mockList: [TaxiLocation] {
    [
      TaxiLocation(
        id: "636c70c308eab94199a3cbff",
        title: "KAIST Main Campus",
        priority: 0,
        latitude: 36.3723596,
        longitude: 127.358697
      ),
      TaxiLocation(
        id: "636c70c408eab94199a3cc05",
        title: "Daejeon Station",
        priority: 1,
        latitude: 36.3319731,
        longitude: 127.4323382
      ),
      TaxiLocation(
        id: "636c70c408eab94199a3cc0d",
        title: "Seodaejeon Station",
        priority: 1.1,
        latitude: 36.3227877,
        longitude: 127.404696
      ),
      TaxiLocation(
        id: "636c70c408eab94199a3cc15",
        title: "Yuseong Express Bus Terminal",
        priority: 1.3,
        latitude: 36.3582923,
        longitude: 127.3363614
      ),
      TaxiLocation(
        id: "636c70c408eab94199a3cc09",
        title: "Gung-dong Rodeo Street",
        priority: 3,
        latitude: 36.3606032,
        longitude: 127.3500644
      ),
      TaxiLocation(
        id: "636c70c408eab94199a3cc0f",
        title: "Shinsegae Department Store",
        priority: 8,
        latitude: 36.3744234,
        longitude: 127.3820715
      )

    ]
  }
}
#endif

