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
    // Keep saved options available when authentication cannot refresh offline.
		try? await timetableService.setup()
		
		guard let timetableUseCase = timetableService.timetableUseCase else {
			throw NSError(domain: "TimetableUseCase Not Initialised", code: -1)
		}
		
		let list: [SemesterWithTimetables] = await TimetableEntity.semesters(timetableUseCase)
		
		let sections: [IntentItemSection<TimetableEntity>] = list
			.compactMap { semester in
				let items: [IntentItem<TimetableEntity>] = TimetableEntity.entities(in: semester)
					.map { IntentItem($0, title: "\($0.name)") }
				
				return IntentItemSection(
					"\(semester.year.formatted(.number.grouping(.never))) \(semester.semester.description)",
					items: items
				)
			}
		
		return ItemCollection(sections: sections)
	}
}
