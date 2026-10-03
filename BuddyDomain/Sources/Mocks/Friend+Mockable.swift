//
//  Friend+Mockable.swift
//  BuddyDomain
//
//  Created by Soongyu Kwon on 28/09/2026.
//

import Foundation

extension Friend: Mockable { }

public extension Friend {
  static var mock: Friend {
    Friend(id: 100, name: "Test Friend", isFavorite: false, hasScheduleNow: true)
  }

  static var mockList: [Friend] {
    [
      Friend(id: 1, name: "Sujin Park", isFavorite: true, hasScheduleNow: true),
      Friend(id: 2, name: "Minho Kim", isFavorite: true, hasScheduleNow: false),
      Friend(id: 3, name: "Jiwoo Lee", isFavorite: false, hasScheduleNow: false),
      Friend(id: 4, name: "Haeun Choi", isFavorite: false, hasScheduleNow: true)
    ]
  }
}
