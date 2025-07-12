//
//  TaxiLocation+Mockable.swift
//  soap
//
//  Created by Soongyu Kwon on 12/07/2025.
//

import Foundation
import MapKit

extension TaxiLocation: Mockable {
  static var mock: TaxiLocation {
    mockList[0]
  }

  static var mockList: [TaxiLocation] {
    [
      TaxiLocation(
        id: "686d4d8f56fd773a8bd9d78e",
        title: LocalizedString([
          "en": "Taxi Stand",
          "ko": "택시승강장"
        ]),
        priority: 0,
        latitude: 36.373199,
        longitude: 127.359507
      ),
      TaxiLocation(
        id: "636c70c408eab94199a3cc05",
        title: LocalizedString([
          "en": "Daejeon Station",
          "ko": "대전역"
        ]),
        priority: 1,
        latitude: 36.3319731,
        longitude: 127.4323382
      ),
      TaxiLocation(
        id: "636c70c408eab94199a3cc0d",
        title: LocalizedString([
          "en": "Seodaejeon Station",
          "ko": "서대전역"
        ]),
        priority: 1.1,
        latitude: 36.3227877,
        longitude: 127.404696
      ),
      TaxiLocation(
        id: "636c70c408eab94199a3cc15",
        title: LocalizedString([
          "en": "Yuseong Express Bus Terminal",
          "ko": "유성 고속버스터미널"
        ]),
        priority: 1.3,
        latitude: 36.3582923,
        longitude: 127.3363614
      ),
      TaxiLocation(
        id: "636c70c408eab94199a3cc09",
        title: LocalizedString([
          "en": "Gung-dong Rodeo Street",
          "ko": "궁동 로데오거리"
        ]),
        priority: 3,
        latitude: 36.3606032,
        longitude: 127.3500644
      ),
      TaxiLocation(
        id: "636c70c408eab94199a3cc0f",
        title: LocalizedString([
          "en": "Shinsegae Department Store",
          "ko": "신세계백화점"
        ]),
        priority: 8,
        latitude: 36.3744234,
        longitude: 127.3820715
      )

    ]
  }
}
