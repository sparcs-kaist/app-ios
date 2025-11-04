//
//  AraBoardGroup+Mockable.swift
//  BuddyData
//
//  Created by 하정우 on 11/4/25.
//

import Foundation
import BuddyDomain

extension AraBoardGroup: Mockable { }

public extension AraBoardGroup {
  static var mock: AraBoardGroup {
    AraBoardGroup(id: 1, slug: "notice", name: LocalizedString([
      "ko": "공지",
      "en": "Notice"
    ]))
  }
  
  static var mockList: [AraBoardGroup] {
    [
      AraBoardGroup(id: 1, slug: "notice", name: LocalizedString([
        "ko": "공지",
        "en": "Notice"
      ])),
      AraBoardGroup(id: 2, slug: "talk", name: LocalizedString([
        "ko": "자유게시판",
        "en": "Talks"
      ])),
      AraBoardGroup(id: 3, slug: "club", name: LocalizedString([
        "ko": "학생 단체 및 동아리",
        "en": "Organizations and Clubs"
      ])),
      AraBoardGroup(id: 4, slug: "trade", name: LocalizedString([
        "ko": "거래",
        "en": "Marketplace"
      ])),
      AraBoardGroup(id: 5, slug: "communication", name: LocalizedString([
        "ko": "소통",
        "en": "Communications"
      ]))
    ]
  }
}
