//
//  AppIntent.swift
//  BuddyiOSWidget
//
//  Created by Soongyu Kwon on 25/12/2025.
//

import WidgetKit
import AppIntents

struct SemesterOptionsProvider: DynamicOptionsProvider {
	func results() async throws -> [String] {
		return [
			"2026 Spring",
			"2025 Autumn"
		]
	}
}

struct ConfigurationAppIntent: WidgetConfigurationIntent {
	static var title: LocalizedStringResource { "Configuration" }
	static var description: IntentDescription { "This is an example widget." }
	
	@Parameter(title: "Mirror My Table", default: true)
	var mirrorTimetable: Bool
	
	@Parameter(title: "Semester", optionsProvider: SemesterOptionsProvider())
	var semester: String?
	
	static var parameterSummary: some ParameterSummary {
		When(\.$mirrorTimetable, .equalTo, false) {
			Summary {
				\.$mirrorTimetable
				\.$semester
			}
		} otherwise: {
			Summary {
				\.$mirrorTimetable
			}
		}
	}
}





