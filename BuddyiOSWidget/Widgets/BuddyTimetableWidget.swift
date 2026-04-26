//
//  BuddyTimetableWidget.swift
//  soap
//
//  Created by Soongyu Kwon on 27/12/2025.
//

import WidgetKit
import SwiftUI
import BuddyDomain
import BuddyDataCore
import BuddyTimetableWidgetUI

struct TimetableProvider: AppIntentTimelineProvider {
  func placeholder(in context: Context) -> TimetableEntry {
    TimetableEntry(
      date: Date(),
      timetable: nil,
      signInRequired: false,
      relevance: .init(score: 50)
    )
  }

  func snapshot(for configuration: TimetableConfigurationIntent, in context: Context) async -> TimetableEntry {
    let now = Date()

    let timetableService = TimetableService()
    try? await timetableService.setup()

    guard let timetableUseCase = timetableService.timetableUseCase else {
      let entry = TimetableEntry(
        date: now,
        timetable: nil,
        signInRequired: true,
        relevance: .init(score: 10)
      )
      return entry
    }

    let timetable: Timetable = await timetableUseCase.getCurrentMyTable()
    let entry = TimetableEntry(
      date: now,
      timetable: timetable,
      signInRequired: false,
      relevance: .init(score: 100)
    )

    return entry
  }

  func timeline(for configuration: TimetableConfigurationIntent, in context: Context) async -> Timeline<TimetableEntry> {
    let now = Date()

    let timetableService = TimetableService()
    try? await timetableService.setup()

    guard let timetableUseCase = timetableService.timetableUseCase else {
      let entry = TimetableEntry(
        date: now,
        timetable: nil,
        signInRequired: true,
        relevance: .init(score: 10)
      )
      return Timeline(entries: [entry], policy: .after(now.addingTimeInterval(60*30)))
    }
		
		if !configuration.mirrorTimetable,
			 let entity = configuration.timetable {
			// user selected timetable
			let timetable: Timetable = await timetableUseCase.getTable(timetableID: entity.id)
			let entry = TimetableEntry(
				date: now,
				timetable: timetable,
				signInRequired: false,
				relevance: .init(score: 100)
			)
			
			return Timeline(entries: [entry], policy: .after(now.addingTimeInterval(60*60)))
		}
		
    let timetable: Timetable = await timetableUseCase.getCurrentMyTable()
    let entry = TimetableEntry(
      date: now,
      timetable: timetable,
      signInRequired: false,
      relevance: .init(score: 100)
    )

    return Timeline(entries: [entry], policy: .after(now.addingTimeInterval(60*60)))
  }
}

struct BuddyTimetableWidgetEntryView: View {
  @Environment(\.widgetFamily) private var family
  var entry: TimetableProvider.Entry

  var body: some View {
    Group {
      switch family {
      case .systemLarge:
        TimetableLargeWidgetView(entry: entry)
      default:
        Text("Not supported", bundle: .module)
      }
    }
  }
}

struct BuddyTimetableWidget: Widget {
  let kind: String = "BuddyTimetableWidget"

  var body: some WidgetConfiguration {
    AppIntentConfiguration(kind: kind, intent: TimetableConfigurationIntent.self, provider: TimetableProvider()) { entry in
      BuddyTimetableWidgetEntryView(entry: entry)
        .containerBackground(.fill.tertiary, for: .widget)
    }
    .supportedFamilies([.systemLarge])
    .configurationDisplayName("Timetable")
    .description("Keep track of your classes.")
  }
}

#Preview(as: .systemLarge) {
  BuddyTimetableWidget()
} timeline: {
  let timetables = Timetable.mockList
  for timetable in timetables {
    TimetableEntry(
      date: Date(),
      timetable: timetable,
      signInRequired: false,
      relevance: .init(score: 50)
    )
  }

  TimetableEntry(date: Date(), timetable: nil, signInRequired: false, relevance: .init(score: 50))
  TimetableEntry(date: Date(), timetable: nil, signInRequired: true, relevance: .init(score: 50))
}
