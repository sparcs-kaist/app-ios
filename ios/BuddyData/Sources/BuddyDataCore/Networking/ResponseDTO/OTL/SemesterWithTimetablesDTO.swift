//
//  SemesterWithTimetablesDTO.swift
//  BuddyData
//
//  Created by Soongyu Kwon on 17/04/2026.
//

import Foundation
import BuddyDomain

struct SemesterWithTimetablesDTO: Codable {
	let year: Int
	let semester: Int
	let timetables: [TimetableHeaderDTO]
}


extension SemesterWithTimetablesDTO {
	func toModel() -> SemesterWithTimetables {
		SemesterWithTimetables(year: year, semester: SemesterType.fromRawValue(semester), timetables: timetables.compactMap { $0.toModel() })
	}
}
