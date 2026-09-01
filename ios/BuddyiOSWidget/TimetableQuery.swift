//
//  TimetableQuery.swift
//  soap
//
//  Created by Soongyu Kwon on 18/04/2026.
//

import AppIntents
import BuddyDomain
import BuddyDataCore

struct TimetableQuery: EntityQuery {
	
	func entities(for identifiers: [Int]) async throws -> [TimetableEntity] {
		let all = try await loadAll()
		return all.filter { identifiers.contains($0.id) }
	}
	
	func suggestedEntities() async throws -> [TimetableEntity] {
		try await loadAll()
	}
	
	private func loadAll() async throws -> [TimetableEntity] {
		let timetableService = TimetableService()
		try await timetableService.setup()
		
		guard let timetableUseCase = timetableService.timetableUseCase else {
			return []
		}
		
		let list: [SemesterWithTimetables] = await timetableUseCase.getTableList()
		
		return list.flatMap { semester in
			semester.timetables.map { timetable in
				TimetableEntity(id: timetable.id, name: timetable.name, year: semester.year, semester: semester.semester)
			}
		}
	}
}
