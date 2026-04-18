//
//  TimetableConfigurationIntent.swift
//  BuddyiOSWidget
//
//  Created by Soongyu Kwon on 25/12/2025.
//

import WidgetKit
import AppIntents

struct TimetableConfigurationIntent: WidgetConfigurationIntent {
	static var title: LocalizedStringResource { "Timetable Configuration" }
	static var description: IntentDescription { "Select timetable for this widget." }
	
	@Parameter(title: "Mirror My Table", default: true)
	var mirrorTimetable: Bool
	
	@Parameter(title: "Timetable", optionsProvider: TimetableOptionsProvider())
	var timetable: TimetableEntity?
	
	static var parameterSummary: some ParameterSummary {
		When(\.$mirrorTimetable, .equalTo, false) {
			Summary {
				\.$mirrorTimetable
				\.$timetable
			}
		} otherwise: {
			Summary {
				\.$mirrorTimetable
			}
		}
	}
}
