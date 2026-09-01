//
//  SemesterWithTimetables.swift
//  BuddyDomain
//
//  Created by Soongyu Kwon on 17/04/2026.
//

import Foundation

public struct SemesterWithTimetables: Codable, Hashable, Sendable {
	public let year: Int
	public let semester: SemesterType
	public let timetables: [TimetableHeader]
	
	public init(year: Int, semester: SemesterType, timetables: [TimetableHeader]) {
		self.year = year
		self.semester = semester
		self.timetables = timetables
	}
}
