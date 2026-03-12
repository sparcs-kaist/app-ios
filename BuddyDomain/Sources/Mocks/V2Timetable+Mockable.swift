//
//  V2Timetable+Mockable.swift
//  BuddyDomain
//
//  Created by Soongyu Kwon on 12/03/2026.
//

import Foundation

extension V2Timetable: Mockable { }

public extension V2Timetable {
    static var mock: V2Timetable {
        V2Timetable(
            id: "0",
            lectures: V2Lecture.mockList
        )
    }

    static var mockList: [V2Timetable] {
        [
            V2Timetable(
                id: "0",
                lectures: Array(V2Lecture.mockList.prefix(2))
            ),
            V2Timetable(
                id: "1",
                lectures: Array(V2Lecture.mockList.prefix(1))
            ),
            V2Timetable(
                id: "2",
                lectures: []
            )
        ]
    }
}
