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
        departAt: Calendar.current.date(byAdding: .hour, value: 1, to: Date())!,
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
        id: "686d4d8f56fd773a86d9d7ad",
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
        departAt: Calendar.current.date(byAdding: .hour, value: 1, to: Date())!,
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
        id: "686d4d8f56f2773a8bd9d7ad",
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
        departAt: Calendar.current.date(byAdding: .hour, value: 1, to: Date())!,
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
        id: "686d4d8f56fd773a8bd9d1b0",
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
        departAt: Calendar.current.date(byAdding: .day, value: 1, to: Date())!,
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
      ),
      TaxiRoom(
        id: "68624d8f56fd773a8bd9d7b0",
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
        departAt: Calendar.current.date(byAdding: .day, value: 1, to: Date())!,
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
      ),
      TaxiRoom(
        id: "686d4d8f56fd773f8bd9d7d0",
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
        departAt: Calendar.current.date(byAdding: .day, value: 1, to: Date())!,
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
      ),
      TaxiRoom(
        id: "686d4d8f56fd773a8bdsd7ad",
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
        departAt: Calendar.current.date(byAdding: .day, value: 2, to: Date())!,
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
        id: "686d4ddf56fd773a86d9d7ad",
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
        departAt: Calendar.current.date(byAdding: .day, value: 2, to: Date())!,
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
        id: "686d4d8f56f2773a8bd0d7ad",
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
        departAt: Calendar.current.date(byAdding: .day, value: 3, to: Date())!,
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
        id: "686d4d8f56fd773a8bdjd7b0",
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
        departAt: Calendar.current.date(byAdding: .day, value: 3, to: Date())!,
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
      ),
      TaxiRoom(
        id: "68624d8f52fd77398id9d7b0",
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
        departAt: Calendar.current.date(byAdding: .day, value: 4, to: Date())!,
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
        departAt: Calendar.current.date(byAdding: .day, value: 5, to: Date())!,
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
      ),
      TaxiRoom(
        id: "606d4d8f56fd773a8bdjd9b0",
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
        departAt: Calendar.current.date(byAdding: .day, value: 5, to: Date())!,
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
      ),
      TaxiRoom(
        id: "68624e8f52fd77398bd9d7d0",
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
        departAt: Calendar.current.date(byAdding: .day, value: 5, to: Date())!,
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
      ),
      TaxiRoom(
        id: "686d4d8f56fdg73a8bd9d9b0",
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
        departAt: Calendar.current.date(byAdding: .day, value: 6, to: Date())!,
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
      ),
      TaxiRoom(
        id: "686d4a8f56fd773aabdjd7b0",
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
        departAt: Calendar.current.date(byAdding: .day, value: 6, to: Date())!,
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
      ),
      TaxiRoom(
        id: "68624d8f52fd77398bd987b0",
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
        departAt: Calendar.current.date(byAdding: .day, value: 6, to: Date())!,
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
      ),
      TaxiRoom(
        id: "686d4d8f56fj773a8bd9d7b0",
        title: "test-2",
        from: TaxiLocationShort(
          id: "646d4d8f56fd773a8bd9d794",
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
        departAt: Calendar.current.date(byAdding: .day, value: 6, to: Date())!,
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
