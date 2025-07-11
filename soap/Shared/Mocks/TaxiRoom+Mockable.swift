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
    let dateFormatter = ISO8601DateFormatter()
    dateFormatter.formatOptions.insert(.withFractionalSeconds)

    return [
      TaxiRoom(
        id: "686d4d8f56fd773a8bd9d7ad",
        title: "test-1",
        from: TaxiLocationShort(
          id: "686d4d8f56fd773a8bd9d7aa",
          title: LocalizedString([
            "en": "Government Complex Intercity Bus Terminal",
            "ko": "대전청사 시외버스터미널"
          ]),
          latitude: 36.361512,
          longitude: 127.379759
        ),
        to: TaxiLocationShort(
          id: "686d4d8f56fd773a8bd9d7a8",
          title: LocalizedString([
            "en": "Government Complex Express Bus Terminal",
            "ko": "대전청사 고속버스터미널"
          ]),
          latitude: 36.361462,
          longitude: 127.390504
        ),
        departAt: Date(timeIntervalSince1970: 1752608143), // 2025-07-15 16:55:43 +0000
        participants: [
          TaxiParticipant(
            id: "686d4d8f56fd773a8bd9d78a",
            name: "tuesday-name",
            nickname: "tuesday-nickname",
            profileImageURL: URL(string: "https://sparcs-taxi-dev.s3.ap-northeast-2.amazonaws.com/profile-img/default/NupjukOTL.png"),
            withdraw: false,
            readAt: Date(timeIntervalSince1970: 1751984143)
          ),
          TaxiParticipant(
            id: "686d4d8f56fd773a8bd9d78c",
            name: "wednesday-name",
            nickname: "wednesday-nickname",
            profileImageURL: URL(string: "https://sparcs-taxi-dev.s3.ap-northeast-2.amazonaws.com/profile-img/default/GooseOTL.png"),
            withdraw: false,
            readAt: Date(timeIntervalSince1970: 1751984143)
          ),
          TaxiParticipant(
            id: "686d4d8c56fd773a8bd9d782",
            name: "sunday-name",
            nickname: "sunday-nickname",
            profileImageURL: URL(string: "https://sparcs-taxi-dev.s3.ap-northeast-2.amazonaws.com/profile-img/default/GooseTaxi.png"),
            withdraw: false,
            readAt: Date(timeIntervalSince1970: 1751984143)
          ),
          TaxiParticipant(
            id: "686d4d8f56fd773a8bd9d788",
            name: "monday-name",
            nickname: "monday-nickname",
            profileImageURL: URL(string: "https://sparcs-taxi-dev.s3.ap-northeast-2.amazonaws.com/profile-img/default/GooseGeoul.png"),
            withdraw: false,
            readAt: Date(timeIntervalSince1970: 1751984143)
          )
        ],
        madeAt: Date(timeIntervalSince1970: 1751984143),
        capacity: 4,
        isDeparted: false
      ),
      TaxiRoom(
        id: "686d4d8f56fd773a8bd9d7b0",
        title: "test-2",
        from: TaxiLocationShort(
          id: "686d4d8f56fd773a8bd9d794",
          title: LocalizedString([
            "en": "Gung-dong Rodeo Street",
            "ko": "궁동 로데오거리"
          ]),
          latitude: 36.362785,
          longitude: 127.350161
        ),
        to: TaxiLocationShort(
          id: "686d4d8f56fd773a8bd9d7a8",
          title: LocalizedString([
            "en": "Government Complex Express Bus Terminal",
            "ko": "대전청사 고속버스터미널"
          ]),
          latitude: 36.361462,
          longitude: 127.390504
        ),
        departAt: Date(timeIntervalSince1970: 1752608143),
        participants: [
          TaxiParticipant(
            id: "686d4d8c56fd773a8bd9d782",
            name: "sunday-name",
            nickname: "sunday-nickname",
            profileImageURL: URL(string: "https://sparcs-taxi-dev.s3.ap-northeast-2.amazonaws.com/profile-img/default/GooseTaxi.png"),
            withdraw: false,
            readAt: Date(timeIntervalSince1970: 1751984143)
          )
        ],
        madeAt: Date(timeIntervalSince1970: 1751984143),
        capacity: 4,
        isDeparted: false
      )
    ]
  }
}
