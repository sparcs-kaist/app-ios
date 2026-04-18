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
	case endOfSemester(date: Date)
	case startOfSemester(date: Date)
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
			type: .endOfSemester(date: Date().addingTimeInterval(600000)),
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
		
		let timetableService = TimetableService()
		try? await timetableService.setup()
		
		guard let timetableUseCase = timetableService.timetableUseCase,
					let semester: Semester = await timetableUseCase.getCurrentSemester() else {
			return DDayEntry(date: now, type: .error, relevance: .init(score: 20))
		}
		
		let begin = semester.beginDate
		let end = semester.endDate
		
		// before start of semester
		if now < begin {
			return DDayEntry(
				date: now,
				type: .startOfSemester(date: begin),
				relevance: .init(score: 100)
			)
		}
		
		return DDayEntry(
			date: now,
			type: .endOfSemester(date: end),
			relevance: .init(score: 100)
		)
	}
}


