//
//  TimetableThemeOptionsProvider.swift
//  soap
//
//  Created by Soongyu Kwon on 14/09/2026.
//

import AppIntents
import BuddyDomain

struct TimetableThemeOptionsProvider: DynamicOptionsProvider {

	func results() async throws -> ItemCollection<TimetableThemeEntity> {
		let store = TimetableThemeStore()

		var sections: [IntentItemSection<TimetableThemeEntity>] = [
			IntentItemSection(
				"Collections",
				items: TimetableTheme.builtIn.map { theme in
					IntentItem(TimetableThemeEntity(theme: theme), title: "\(theme.displayName)")
				}
			)
		]

		let customThemes = store.customThemes
		if !customThemes.isEmpty {
			sections.append(
				IntentItemSection(
					"My Themes",
					items: customThemes.map { theme in
						IntentItem(TimetableThemeEntity(theme: theme), title: "\(theme.displayName)")
					}
				)
			)
		}

		return ItemCollection(sections: sections)
	}
}
