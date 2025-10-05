//
//  Timetable+Mockable.swift
//  soap
//
//  Created by Soongyu Kwon on 28/12/2024.
//

import Foundation
import BuddyDomain

extension Timetable: Mockable {
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
                lectures: Array(Lecture.mockList.prefix(4))
            ),
            Timetable(
                id: "2",
                lectures: Array(Lecture.mockList.prefix(1))
            ),
            Timetable(
                id: "3",
                lectures: Array(Lecture.mockList.prefix(5))
            )
        ]
    }
}
