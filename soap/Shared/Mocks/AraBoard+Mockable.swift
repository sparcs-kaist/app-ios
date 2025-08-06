//
//  AraBoard+Mockable.swift
//  soap
//
//  Created by Soongyu Kwon on 15/02/2025.
//

import Foundation

#if DEBUG
extension AraBoard: Mockable {
  static var mock: AraBoard {
    AraBoard(
      id: 1,
      slug: "portal-notice",
      name: LocalizedString([
        "ko": "포탈공지",
        "en": "Portal Notice"
      ]),
      group: AraBoardGroup(
        id: 1,
        slug: "notice",
        name: LocalizedString([
          "ko": "공지",
          "en": "Notices"
        ])
      ),
      topics: [],
      isReadOnly: true,
      userReadable: true,
      userWritable: false
    )
  }

  static var mockList: [AraBoard] {
    [
      AraBoard(
        id: 1,
        slug: "portal-notice",
        name: LocalizedString([
          "ko": "포탈공지",
          "en": "Portal Notice"
        ]),
        group: AraBoardGroup(
          id: 1,
          slug: "notice",
          name: LocalizedString([
            "ko": "공지",
            "en": "Notices"
          ])
        ),
        topics: [],
        isReadOnly: true,
        userReadable: true,
        userWritable: false
      ),
      AraBoard(
        id: 2,
        slug: "students-group",
        name: LocalizedString([
          "ko": "학생 단체",
          "en": "Student Organizations"
        ]),
        group: AraBoardGroup(
          id: 3,
          slug: "club",
          name: LocalizedString([
            "ko": "학생 단체 및 동아리",
            "en": "Organizations and Clubs"
          ])
        ),
        topics: [
          AraBoardTopic(
            id: 24,
            slug: "grad-assoc",
            name: LocalizedString([
              "ko": "원총",
              "en": "Grad Assoc"
            ])
          ),
          AraBoardTopic(
            id: 9,
            slug: "imgeffect",
            name: LocalizedString([
              "ko": "상상효과",
              "en": "IMGEFFECT"
            ])
          ),
          AraBoardTopic(
            id: 8,
            slug: "times",
            name: LocalizedString([
              "ko": "신문사",
              "en": "Times"
            ])
          ),
          AraBoardTopic(
            id: 7,
            slug: "kcoop",
            name: LocalizedString([
              "ko": "협동조합",
              "en": "Kcoop"
            ])
          ),
          AraBoardTopic(
            id: 6,
            slug: "scspace",
            name: LocalizedString([
              "ko": "공간위",
              "en": "SCSpace"
            ])
          ),
          AraBoardTopic(
            id: 5,
            slug: "freshman-council",
            name: LocalizedString([
              "ko": "새학",
              "en": "Freshman Council"
            ])
          ),
          AraBoardTopic(
            id: 4,
            slug: "welfare-cmte",
            name: LocalizedString([
              "ko": "학복위",
              "en": "Welfare Cmte"
            ])
          ),
          AraBoardTopic(
            id: 3,
            slug: "dorm-council",
            name: LocalizedString([
              "ko": "생자회",
              "en": "Dorm Council"
            ])
          ),
          AraBoardTopic(
            id: 2,
            slug: "clubs-union",
            name: LocalizedString([
              "ko": "동연",
              "en": "Clubs Union"
            ])
          ),
          AraBoardTopic(
            id: 1,
            slug: "undergrad-assoc",
            name: LocalizedString([
              "ko": "총학",
              "en": "Undergrad Assoc"
            ])
          )
        ],
        isReadOnly: false,
        userReadable: true,
        userWritable: true
      ),
      AraBoard(
        id: 3,
        slug: "wanted",
        name: LocalizedString([
          "ko": "구인구직",
          "en": "Jobs & Hiring"
        ]),
        group: AraBoardGroup(
          id: 4,
          slug: "trade",
          name: LocalizedString([
            "ko": "거래",
            "en": "Marketplace"
          ])
        ),
        topics: [
          AraBoardTopic(
            id: 19,
            slug: "carpool",
            name: LocalizedString([
              "ko": "카풀",
              "en": "Carpool"
            ])
          ),
          AraBoardTopic(
            id: 18,
            slug: "dorm",
            name: LocalizedString([
              "ko": "기숙사",
              "en": "Dorm"
            ])
          ),
          AraBoardTopic(
            id: 17,
            slug: "experiment",
            name: LocalizedString([
              "ko": "실험",
              "en": "Experiment"
            ])
          ),
          AraBoardTopic(
            id: 16,
            slug: "job",
            name: LocalizedString([
              "ko": "채용",
              "en": "Job"
            ])
          ),
          AraBoardTopic(
            id: 15,
            slug: "intern",
            name: LocalizedString([
              "ko": "인턴",
              "en": "Intern"
            ])
          ),
          AraBoardTopic(
            id: 14,
            slug: "tutoring",
            name: LocalizedString([
              "ko": "과외",
              "en": "Tutoring"
            ])
          )
        ],
        isReadOnly: false,
        userReadable: true,
        userWritable: true
      ),
      AraBoard(
        id: 4,
        slug: "market",
        name: LocalizedString([
          "ko": "장터",
          "en": "Buy & Sell"
        ]),
        group: AraBoardGroup(
          id: 4,
          slug: "trade",
          name: LocalizedString([
            "ko": "거래",
            "en": "Marketplace"
          ])
        ),
        topics: [
          AraBoardTopic(
            id: 22,
            slug: "sell",
            name: LocalizedString([
              "ko": "팝니다",
              "en": "Sell"
            ])
          ),
          AraBoardTopic(
            id: 21,
            slug: "buy",
            name: LocalizedString([
              "ko": "삽니다",
              "en": "Buy"
            ])
          ),
          AraBoardTopic(
            id: 20,
            slug: "housing",
            name: LocalizedString([
              "ko": "부동산",
              "en": "Housing"
            ])
          )
        ],
        isReadOnly: false,
        userReadable: true,
        userWritable: true
      ),
      AraBoard(
        id: 5,
        slug: "facility-feedback",
        name: LocalizedString([
          "ko": "입주 업체 피드백",
          "en": "Tenant Feedback"
        ]),
        group: AraBoardGroup(
          id: 5,
          slug: "communication",
          name: LocalizedString([
            "ko": "소통",
            "en": "Communications"
          ])
        ),
        topics: [
          AraBoardTopic(
            id: 23,
            slug: "events",
            name: LocalizedString([
              "ko": "이벤트",
              "en": "Event"
            ])
          )
        ],
        isReadOnly: false,
        userReadable: true,
        userWritable: true
      ),
      AraBoard(
        id: 7,
        slug: "talk",
        name: LocalizedString([
          "ko": "자유게시판",
          "en": "Talk"
        ]),
        group: AraBoardGroup(
          id: 2,
          slug: "talk",
          name: LocalizedString([
            "ko": "자유게시판",
            "en": "Talks"
          ])
        ),
        topics: [
          AraBoardTopic(
            id: 26,
            slug: "spangs",
            name: LocalizedString([
              "ko": "스빵스",
              "en": "SPANGS"
            ])
          ),
          AraBoardTopic(
            id: 25,
            slug: "meal",
            name: LocalizedString([
              "ko": "식사",
              "en": "Meal"
            ])
          ),
          AraBoardTopic(
            id: 13,
            slug: "money",
            name: LocalizedString([
              "ko": "돈",
              "en": "Money"
            ])
          ),
          AraBoardTopic(
            id: 12,
            slug: "game",
            name: LocalizedString([
              "ko": "게임",
              "en": "Game"
            ])
          ),
          AraBoardTopic(
            id: 11,
            slug: "love",
            name: LocalizedString([
              "ko": "연애",
              "en": "Dating"
            ])
          ),
          AraBoardTopic(
            id: 10,
            slug: "lostfound",
            name: LocalizedString([
              "ko": "분실물",
              "en": "Lost & Found"
            ])
          )
        ],
        isReadOnly: false,
        userReadable: true,
        userWritable: true
      ),
      AraBoard(
        id: 8,
        slug: "ara-notice",
        name: LocalizedString([
          "ko": "운영진 공지",
          "en": "Staff Notice"
        ]),
        group: AraBoardGroup(
          id: 1,
          slug: "notice",
          name: LocalizedString([
            "ko": "공지",
            "en": "Notices"
          ])
        ),
        topics: [],
        isReadOnly: true,
        userReadable: true,
        userWritable: false
      ),
      AraBoard(
        id: 11,
        slug: "facility-notice",
        name: LocalizedString([
          "ko": "입주 업체 공지",
          "en": "Tenant Notice"
        ]),
        group: AraBoardGroup(
          id: 1,
          slug: "notice",
          name: LocalizedString([
            "ko": "공지",
            "en": "Notices"
          ])
        ),
        topics: [],
        isReadOnly: false,
        userReadable: true,
        userWritable: true
      ),
      AraBoard(
        id: 12,
        slug: "club",
        name: LocalizedString([
          "ko": "동아리",
          "en": "Club"
        ]),
        group: AraBoardGroup(
          id: 3,
          slug: "club",
          name: LocalizedString([
            "ko": "학생 단체 및 동아리",
            "en": "Organizations and Clubs"
          ])
        ),
        topics: [],
        isReadOnly: false,
        userReadable: true,
        userWritable: true
      ),
      AraBoard(
        id: 13,
        slug: "real-estate",
        name: LocalizedString([
          "ko": "부동산",
          "en": "Real Estate"
        ]),
        group: AraBoardGroup(
          id: 4,
          slug: "trade",
          name: LocalizedString([
            "ko": "거래",
            "en": "Marketplace"
          ])
        ),
        topics: [],
        isReadOnly: false,
        userReadable: true,
        userWritable: true
      ),
      AraBoard(
        id: 14,
        slug: "with-school",
        name: LocalizedString([
          "ko": "학교에게 전합니다",
          "en": "Speak to the School"
        ]),
        group: AraBoardGroup(
          id: 5,
          slug: "communication",
          name: LocalizedString([
            "ko": "소통",
            "en": "Communications"
          ])
        ),
        topics: [],
        isReadOnly: false,
        userReadable: true,
        userWritable: true
      ),
      AraBoard(
        id: 10,
        slug: "ara-feedback",
        name: LocalizedString([
          "ko": "아라 피드백",
          "en": "Ara Feedback"
        ]),
        group: AraBoardGroup(
          id: 5,
          slug: "communication",
          name: LocalizedString([
            "ko": "소통",
            "en": "Communications"
          ])
        ),
        topics: [],
        isReadOnly: false,
        userReadable: true,
        userWritable: true
      ),
      AraBoard(
        id: 17,
        slug: "kaist-news",
        name: LocalizedString([
          "ko": "카이스트 뉴스",
          "en": "KAIST News"
        ]),
        group: AraBoardGroup(
          id: 5,
          slug: "communication",
          name: LocalizedString([
            "ko": "소통",
            "en": "Communications"
          ])
        ),
        topics: [],
        isReadOnly: false,
        userReadable: true,
        userWritable: false
      ),
      AraBoard(
        id: 18,
        slug: "external-company-advertisement",
        name: LocalizedString([
          "ko": "외부 업체 홍보",
          "en": "External Company Advertisement"
        ]),
        group: AraBoardGroup(
          id: 1,
          slug: "notice",
          name: LocalizedString([
            "ko": "공지",
            "en": "Notices"
          ])
        ),
        topics: [],
        isReadOnly: false,
        userReadable: true,
        userWritable: false
      )
    ]
  }
}
#endif 
