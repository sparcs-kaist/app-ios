//
//  Timetable+Mockable.swift
//  BuddyDomain
//
//  Created by Soongyu Kwon on 12/03/2026.
//

import Foundation

extension Timetable: Mockable { }

public extension Timetable {
    static var mock: Timetable {
        Timetable(
            id: "0",
            lectures: Lecture.mockList
        )
    }

    static var mockList: [Timetable] {
        [
            Timetable(
                id: "0",
                lectures: Array(Lecture.mockList.prefix(2))
            ),
            Timetable(
                id: "1",
                lectures: Array(Lecture.mockList.prefix(1))
            ),
            Timetable(
                id: "2",
                lectures: []
            )
        ]
    }
}
