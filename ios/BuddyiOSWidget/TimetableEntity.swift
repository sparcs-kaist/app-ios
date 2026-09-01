//
//  TimetableEntity.swift
//  soap
//
//  Created by Soongyu Kwon on 18/04/2026.
//

import AppIntents
import BuddyDomain

struct TimetableEntity: AppEntity {
	let id: Int
	let name: String
	
	let year: Int
	let semester: SemesterType
	
	static var typeDisplayRepresentation = TypeDisplayRepresentation(
		name: "Timetable"
	)
	
	var displayRepresentation: DisplayRepresentation {
		DisplayRepresentation(
			title: "\(name)"
		)
	}
	
	static var defaultQuery = TimetableQuery()
}
