//
//  TimetableBySemesterList.swift
//  BuddyDomain
//
//  Created by Soongyu Kwon on 17/04/2026.
//

import Foundation

public struct TimetableBySemesterList: Codable, Hashable, Sendable {
	public let semesters: [SemesterWithTimetables]
	
	public init(semesters: [SemesterWithTimetables]) {
		self.semesters = semesters
	}
}
