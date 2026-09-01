//
//  TaxiLocation+Mockable.swift
//  soap
//
//  Created by Soongyu Kwon on 12/07/2025.
//

import Foundation
import MapKit

extension TaxiLocation: Mockable { }

public extension TaxiLocation {
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
        id: "686d4d8f56fd773a8bd9d790",
        title: LocalizedString([
          "en": "Daejeon Station",
          "ko": "대전역"
        ]),
        priority: 0,
        latitude: 36.331894,
        longitude: 127.434522
      ),
      TaxiLocation(
        id: "686d4d8f56fd773a8bd9d792",
        title: LocalizedString([
          "en": "Galleria Timeworld",
          "ko": "갤러리아 타임월드"
        ]),
        priority: 0,
        latitude: 36.351938,
        longitude: 127.378188
      ),
      TaxiLocation(
        id: "686d4d8f56fd773a8bd9d794",
        title: LocalizedString([
          "en": "Gung-dong Rodeo Street",
          "ko": "궁동 로데오거리"
        ]),
        priority: 0,
        latitude: 36.362785,
        longitude: 127.350161
      ),
      TaxiLocation(
        id: "686d4d8f56fd773a8bd9d796",
        title: LocalizedString([
          "en": "Daejeon Terminal Complex",
          "ko": "대전복합터미널"
        ]),
        priority: 0,
        latitude: 36.349766,
        longitude: 127.43688
      ),
      TaxiLocation(
        id: "686d4d8f56fd773a8bd9d798",
        title: LocalizedString([
          "en": "Mannyon Middle School",
          "ko": "만년중학교"
        ]),
        priority: 0,
        latitude: 36.36699,
        longitude: 127.375993
      ),
      TaxiLocation(
        id: "686d4d8f56fd773a8bd9d79a",
        title: LocalizedString([
          "en": "Seodaejeon Station",
          "ko": "서대전역"
        ]),
        priority: 0,
        latitude: 36.322517,
        longitude: 127.403933
      ),
      TaxiLocation(
        id: "686d4d8f56fd773a8bd9d79c",
        title: LocalizedString([
          "en": "Shinsegae Department Store",
          "ko": "신세계백화점"
        ]),
        priority: 0,
        latitude: 36.375168,
        longitude: 127.381905
      ),
      TaxiLocation(
        id: "686d4d8f56fd773a8bd9d79e",
        title: LocalizedString([
          "en": "Duck Pond",
          "ko": "오리연못"
        ]),
        priority: 0,
        latitude: 36.367715,
        longitude: 127.362371
      ),
      TaxiLocation(
        id: "686d4d8f56fd773a8bd9d7a0",
        title: LocalizedString([
          "en": "Wolpyeong Station",
          "ko": "월평역"
        ]),
        priority: 0,
        latitude: 36.358271,
        longitude: 127.364352
      ),
      TaxiLocation(
        id: "686d4d8f56fd773a8bd9d7a2",
        title: LocalizedString([
          "en": "Yuseong-gu Office",
          "ko": "유성구청"
        ]),
        priority: 0,
        latitude: 36.362084,
        longitude: 127.356384
      ),
      TaxiLocation(
        id: "686d4d8f56fd773a8bd9d7a4",
        title: LocalizedString([
          "en": "Yuseong Express Bus Terminal",
          "ko": "유성 고속버스터미널"
        ]),
        priority: 0,
        latitude: 36.358279,
        longitude: 127.336467
      ),
      TaxiLocation(
        id: "686d4d8f56fd773a8bd9d7a6",
        title: LocalizedString([
          "en": "Yuseong Intercity Bus Terminal",
          "ko": "유성 시외버스터미널"
        ]),
        priority: 0,
        latitude: 36.355604,
        longitude: 127.335971
      ),
      TaxiLocation(
        id: "686d4d8f56fd773a8bd9d7a8",
        title: LocalizedString([
          "en": "Government Complex Express Bus Terminal",
          "ko": "대전청사 고속버스터미널"
        ]),
        priority: 0,
        latitude: 36.361462,
        longitude: 127.390504
      ),
      TaxiLocation(
        id: "686d4d8f56fd773a8bd9d7aa",
        title: LocalizedString([
          "en": "Government Complex Intercity Bus Terminal",
          "ko": "대전청사 시외버스터미널"
        ]),
        priority: 0,
        latitude: 36.361512,
        longitude: 127.379759
      )
    ]
  }
}
