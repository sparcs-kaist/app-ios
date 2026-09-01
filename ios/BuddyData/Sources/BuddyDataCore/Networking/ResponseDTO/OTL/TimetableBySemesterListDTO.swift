//
//  TimetableBySemesterListDTO.swift
//  BuddyData
//
//  Created by Soongyu Kwon on 17/04/2026.
//

import Foundation
import BuddyDomain

struct TimetableBySemesterListDTO: Codable {
	let semesters: [SemesterWithTimetablesDTO]
}


extension TimetableBySemesterListDTO {
	func toModel() -> TimetableBySemesterList {
		TimetableBySemesterList(semesters: semesters.compactMap { $0.toModel() })
	}
}
