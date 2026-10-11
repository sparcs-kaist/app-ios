//
//  WidgetTimetableLoader.swift
//  BuddyiOSWidget
//

import BuddyDomain
import BuddyDataCore

/// Picks the timetable a widget shows: the configured one, or, in Mirror mode,
/// the timetable selected in Buddy (the same one Siri and the watch use).
enum WidgetTimetableLoader {
	static func timetable(
		for configuration: TimetableConfigurationIntent,
		useCase: TimetableUseCaseBackgroundProtocol
	) async -> Timetable {
		if !configuration.mirrorTimetable, let reference = configuration.timetable?.reference {
			switch reference {
			case .table(let id):
				return await useCase.getTable(timetableID: id)
			case .myTable(let year, let semester):
				return await useCase.getMyTable(year: year, semester: semester)
			}
		}

		if let active = await ActiveTimetableResolver(useCase: useCase).resolve(includingTitle: false) {
			return active.timetable
		}
		return await useCase.getCurrentMyTable()
	}
}
