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
import BuddyDDayWidgetUI

struct DDayProvider: TimelineProvider {
	
	func placeholder(in context: Context) -> DDayEntry {
		DDayEntry(
			date: Date(),
			type: .endOfSemester(daysLeft: 0, progress: 1),
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
			
			// Refresh every hour to update the percentage bar
			let nextUpdate = Calendar.current.date(byAdding: .hour, value: 1, to: Date()) ?? Date().addingTimeInterval(3600)
			
			let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
			completion(timeline)
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
		
		let begin = semester.beginDate
		let end = semester.endDate
		
		// 1. Before start of semester
		if now < begin {
			let daysUntil = calendar.dateComponents([.day], from: calendar.startOfDay(for: now), to: calendar.startOfDay(for: begin)).day ?? 0
			return DDayEntry(date: now, type: .startOfSemester(daysUntil: daysUntil), relevance: .init(score: 100))
		}
		
		// 2. During semester: Calculate Percentage
		let totalDuration = end.timeIntervalSince(begin)
		let elapsed = now.timeIntervalSince(begin)
		// Clamp the progress between 0.0 and 1.0
		let progress = max(0, min(1, elapsed / totalDuration))
		
		let daysLeft = calendar.dateComponents([.day], from: calendar.startOfDay(for: now), to: calendar.startOfDay(for: end)).day ?? 0
		
		return DDayEntry(
			date: now,
			type: .endOfSemester(daysLeft: daysLeft, progress: progress),
			relevance: .init(score: 100)
		)
	}
}

struct BuddyDDayWidgetEntryView: View {
	@Environment(\.widgetFamily) private var familiy
	var entry: DDayProvider.Entry
	
	var body: some View {
		Group {
			switch familiy {
			case .accessoryInline:
				DDayInlineWidgetView(entry: entry)
			case .accessoryCircular:
				DDayCircularWidgetView(entry: entry)
			default:
				Text("Not supported")
			}
		}
	}
}

struct BuddyDDayWidget: Widget {
	let kind: String = "BuddyDDayWidget"
	
	var body: some WidgetConfiguration {
		StaticConfiguration(kind: kind, provider: DDayProvider()) { entry in
			BuddyDDayWidgetEntryView(entry: entry)
		}
		.supportedFamilies([
			.accessoryInline, .accessoryCircular
		])
		.configurationDisplayName("D-Day")
		.description("Track D-Day for this semester.")
	}
}

#Preview(as: .accessoryCircular) {
	BuddyDDayWidget()
} timeline: {
	DDayEntry(date: Date(), type: .endOfSemester(daysLeft: 10, progress: 0.8), relevance: .init(score: 100))
}
