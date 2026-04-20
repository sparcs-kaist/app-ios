//
//  BuddyDDayWidget.swift
//  soap
//
//  Created by Soongyu Kwon on 18/04/2026.
//

import WidgetKit
import SwiftUI
import BuddyDomain
import BuddyDataCore

public enum DDayEntryType {
	case endOfSemester(daysLeft: Int)
	case startOfSemester(daysUntil: Int)
	case error
}

public struct DDayEntry: TimelineEntry {
	public let date: Date
	public let type: DDayEntryType
	public let relevance: TimelineEntryRelevance
	
	public init(date: Date, type: DDayEntryType, relevance: TimelineEntryRelevance) {
		self.date = date
		self.type = type
		self.relevance = relevance
	}
}

struct DDayProvider: TimelineProvider {
	
	func placeholder(in context: Context) -> DDayEntry {
		DDayEntry(
			date: Date(),
			type: .endOfSemester(daysLeft: 0),
			relevance: .init(score: 100)
		)
	}
	
	func getSnapshot(in context: Context, completion: @escaping (DDayEntry) -> Void) {
		Task {
			let entry = await makeEntry()
			completion(entry)
		}
	}
	
	func getTimeline(in context: Context, completion: @escaping (Timeline<DDayEntry>) -> Void) {
		Task {
			let entry = await makeEntry()
			
			let nextUpdate = Calendar.current.nextDate(
				after: Date(),
				matching: DateComponents(hour: 0, minute: 0),
				matchingPolicy: .nextTime
			) ?? Date().addingTimeInterval(60 * 60 * 6)
			
			completion(Timeline(entries: [entry], policy: .after(nextUpdate)))
		}
	}
	
	private func makeEntry() async -> DDayEntry {
		let now = Date()
		let calendar = Calendar.current
		
		let timetableService = TimetableService()
		try? await timetableService.setup()
		
		guard let timetableUseCase = timetableService.timetableUseCase,
					let semester: Semester = await timetableUseCase.getCurrentSemester() else {
			return DDayEntry(date: now, type: .error, relevance: .init(score: 20))
		}
		
		// Normalize dates to the start of the day for accurate "day" counting
		let startOfToday = calendar.startOfDay(for: now)
		let startOfBegin = calendar.startOfDay(for: semester.beginDate)
		let startOfEnd = calendar.startOfDay(for: semester.endDate)
		
		// Before start of semester
		if startOfToday < startOfBegin {
			let components = calendar.dateComponents([.day], from: startOfToday, to: startOfBegin)
			let daysUntil = components.day ?? 0
			return DDayEntry(
				date: now,
				type: .startOfSemester(daysUntil: daysUntil),
				relevance: .init(score: 100)
			)
		}
		
		// During semester (counting down to the end)
		let components = calendar.dateComponents([.day], from: startOfToday, to: startOfEnd)
		let daysLeft = components.day ?? 0
		return DDayEntry(
			date: now,
			type: .endOfSemester(daysLeft: daysLeft),
			relevance: .init(score: 100)
		)
	}

}


