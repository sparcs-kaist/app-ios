//
//  TimetableConfigurationIntent.swift
//  BuddyiOSWidget
//
//  Created by Soongyu Kwon on 25/12/2025.
//

import WidgetKit
import AppIntents
import BuddyDomain

struct TimetableConfigurationIntent: WidgetConfigurationIntent {
	static var title: LocalizedStringResource { "Timetable Configuration" }
	static var description: IntentDescription { "Select timetable for this widget." }
	
	@Parameter(title: "Mirror My Table", default: true)
	var mirrorTimetable: Bool
	
	@Parameter(title: "Timetable", optionsProvider: TimetableOptionsProvider())
	var timetable: TimetableEntity?

	/// Starts on the Default theme so the field is never blank. Widgets configured
	/// before this parameter existed have no value stored and follow the theme
	/// chosen in Settings instead.
	@Parameter(
		title: "Theme",
		default: TimetableThemeEntity(theme: .default),
		optionsProvider: TimetableThemeOptionsProvider()
	)
	var theme: TimetableThemeEntity?

	static var parameterSummary: some ParameterSummary {
		When(\.$mirrorTimetable, .equalTo, false) {
			Summary {
				\.$mirrorTimetable
				\.$timetable
				\.$theme
			}
		} otherwise: {
			Summary {
				\.$mirrorTimetable
				\.$theme
			}
		}
	}
}
