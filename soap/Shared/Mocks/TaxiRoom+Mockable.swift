//
//  TaxiRoom+Mockable.swift
//  soap
//
//  Created by Soongyu Kwon on 12/07/2025.
//

import Foundation

extension TaxiRoom: Mockable {
  static var mock: TaxiRoom {
    mockList[0]
  }

  static var mockList: [TaxiRoom] {
    let baseDate = Date().addingTimeInterval(3600)

    let locations: [TaxiLocationShort] = [
      .init(id: "686d4d8f56fd773a8bd9d78e", title: LocalizedString(["en": "Taxi Stand", "ko": "택시승강장"]), latitude: 36.373199, longitude: 127.359507),
      .init(id: "686d4d8f56fd773a8bd9d790", title: LocalizedString(["en": "Daejeon Station", "ko": "대전역"]), latitude: 36.331894, longitude: 127.434522),
      .init(id: "686d4d8f56fd773a8bd9d792", title: LocalizedString(["en": "Galleria Timeworld", "ko": "갤러리아 타임월드"]), latitude: 36.351938, longitude: 127.378188),
      .init(id: "686d4d8f56fd773a8bd9d794", title: LocalizedString(["en": "Gung-dong Rodeo Street", "ko": "궁동 로데오거리"]), latitude: 36.362785, longitude: 127.350161),
      .init(id: "686d4d8f56fd773a8bd9d796", title: LocalizedString(["en": "Daejeon Terminal Complex", "ko": "대전복합터미널"]), latitude: 36.349766, longitude: 127.43688),
      .init(id: "686d4d8f56fd773a8bd9d79a", title: LocalizedString(["en": "Seodaejeon Station", "ko": "서대전역"]), latitude: 36.322517, longitude: 127.403933),
      .init(id: "686d4d8f56fd773a8bd9d79c", title: LocalizedString(["en": "Shinsegae Department Store", "ko": "신세계백화점"]), latitude: 36.375168, longitude: 127.381905),
      .init(id: "686d4d8f56fd773a8bd9d7a0", title: LocalizedString(["en": "Wolpyeong Station", "ko": "월평역"]), latitude: 36.358271, longitude: 127.364352),
      .init(id: "686d4d8f56fd773a8bd9d7a2", title: LocalizedString(["en": "Yuseong-gu Office", "ko": "유성구청"]), latitude: 36.362084, longitude: 127.356384),
      .init(id: "686d4d8f56fd773a8bd9d7a8", title: LocalizedString(["en": "Government Complex Express Bus Terminal", "ko": "대전청사 고속버스터미널"]), latitude: 36.361462, longitude: 127.390504)
    ]

    let participants: [TaxiParticipant] = [
      .init(id: "686d4d8f56fd773a8bd9d78a", name: "tuesday-name", nickname: "tuesday-nickname", profileImageURL: URL(string: "https://sparcs-taxi-dev.s3.ap-northeast-2.amazonaws.com/profile-img/default/NupjukOTL.png"), withdraw: false, readAt: baseDate),
      .init(id: "686d4d8f56fd773a8bd9d78c", name: "wednesday-name", nickname: "wednesday-nickname", profileImageURL: URL(string: "https://sparcs-taxi-dev.s3.ap-northeast-2.amazonaws.com/profile-img/default/GooseOTL.png"), withdraw: false, readAt: baseDate)
    ]

    return (0..<18).map { index in
      TaxiRoom(
        id: UUID().uuidString,
        title: "Mock Room \(index + 1)",
        from: locations[index % locations.count],
        to: locations[(index + 3) % locations.count],
        departAt: Calendar.current.date(byAdding: .day, value: index % 7, to: baseDate)!,
        participants: participants,
        madeAt: baseDate,
        capacity: 4,
        isDeparted: false
      )
    }
  }
}
