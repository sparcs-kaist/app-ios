//
//  TimetableEntity.swift
//  soap
//
//  Created by Soongyu Kwon on 18/04/2026.
//

import AppIntents
import BuddyDomain

struct TimetableEntity: AppEntity {
	/// A server table ID, or a semester's My Table encoded by `TimetableReference`.
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

	var reference: TimetableReference? { TimetableReference(entityID: id) }

	/// The given semester's My Table.
	static func myTable(year: Int, semester: SemesterType) -> TimetableEntity {
		TimetableEntity(
			id: TimetableReference.myTable(year: year, semester: semester).entityID,
			name: String(localized: "My Table"),
			year: year,
			semester: semester
		)
	}

	/// The semester's My Table followed by its user tables.
	static func entities(in semester: SemesterWithTimetables) -> [TimetableEntity] {
		[.myTable(year: semester.year, semester: semester.semester)] + semester.timetables.map { timetable in
			TimetableEntity(id: timetable.id, name: timetable.name, year: semester.year, semester: semester.semester)
		}
	}

	/// Semesters with user tables, plus the current semester so its My Table is
	/// offered even before the user creates a table. Newest first.
	static func semesters(_ useCase: TimetableUseCaseBackgroundProtocol) async -> [SemesterWithTimetables] {
		var list = await useCase.getTableList()
		if let current = await useCase.getCurrentSemester(),
			 !list.contains(where: { $0.year == current.year && $0.semester == current.semesterType }) {
			list.append(SemesterWithTimetables(year: current.year, semester: current.semesterType, timetables: []))
		}
		return list.sorted { ($0.year, $0.semester) > ($1.year, $1.semester) }
	}
}
