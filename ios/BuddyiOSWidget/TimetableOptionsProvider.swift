//
//  TimetableOptionsProvider.swift
//  soap
//
//  Created by Soongyu Kwon on 18/04/2026.
//

import AppIntents
import BuddyDomain
import BuddyDataCore

struct TimetableOptionsProvider: DynamicOptionsProvider {
	
	func results() async throws -> ItemCollection<TimetableEntity> {
		let timetableService = TimetableService()
		try await timetableService.setup()
		
		guard let timetableUseCase = timetableService.timetableUseCase else {
			throw NSError(domain: "TimetableUseCase Not Initialised", code: -1)
		}
		
		let list: [SemesterWithTimetables] = await timetableUseCase.getTableList()
		
		let sections: [IntentItemSection<TimetableEntity>] = list
			.sorted {
				($0.year, $0.semester.rawValue) > ($1.year, $1.semester.rawValue)
			}
			.compactMap { semester in
				let items: [IntentItem<TimetableEntity>] = semester.timetables
					.map { timetable in
						let entity = TimetableEntity(
							id: timetable.id,
							name: timetable.name,
							year: semester.year,
							semester: semester.semester
						)
						
						return IntentItem(entity, title: "\(timetable.name)")
					}
				
				return IntentItemSection(
					"\(semester.year.formatted(.number.grouping(.never))) \(semester.semester.description)",
					items: items
				)
			}
		
		return ItemCollection(sections: sections)
	}
}
