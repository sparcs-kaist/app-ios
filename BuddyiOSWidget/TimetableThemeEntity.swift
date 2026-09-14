//
//  TimetableThemeEntity.swift
//  soap
//
//  Created by Soongyu Kwon on 14/09/2026.
//

import AppIntents
import BuddyDomain

struct TimetableThemeEntity: AppEntity {
	/// Matches `TimetableTheme.id`, which is stable across launches and devices.
	let id: String
	let name: String

	static var typeDisplayRepresentation = TypeDisplayRepresentation(
		name: "Timetable Theme"
	)

	var displayRepresentation: DisplayRepresentation {
		DisplayRepresentation(
			title: "\(name)"
		)
	}

	static var defaultQuery = TimetableThemeQuery()

	init(theme: TimetableTheme) {
		self.id = theme.id
		self.name = theme.displayName
	}
}

struct TimetableThemeQuery: EntityQuery {
	func entities(for identifiers: [String]) async throws -> [TimetableThemeEntity] {
		let store = TimetableThemeStore()
		return identifiers.compactMap { store.theme(id: $0) }.map(TimetableThemeEntity.init)
	}

	func suggestedEntities() async throws -> [TimetableThemeEntity] {
		TimetableThemeStore().allThemes.map(TimetableThemeEntity.init)
	}
}
