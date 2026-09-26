//
//  BuddyCreditsWidget.swift
//  BuddyiOSWidget
//
//  Created by Soongyu Kwon on 26/09/2026.
//

import WidgetKit
import SwiftUI
import BuddyDomain
import BuddyDataCore
import BuddySharedUI

/// Reads the totals the app last computed; the widget doesn't compute them itself.
/// The app reloads this widget whenever they change, so the schedule is a fallback.
struct CreditsProvider: TimelineProvider {
  func placeholder(in context: Context) -> CreditsEntry {
    .sample
  }

  func getSnapshot(in context: Context, completion: @escaping (CreditsEntry) -> Void) {
    // The widget gallery shows sample values until the app has computed real ones.
    let entry = currentEntry()
    completion(context.isPreview && entry.snapshot == nil ? .sample : entry)
  }

  func getTimeline(in context: Context, completion: @escaping (Timeline<CreditsEntry>) -> Void) {
    completion(Timeline(entries: [currentEntry()], policy: .after(.now.addingTimeInterval(60 * 60 * 12))))
  }

  private func currentEntry() -> CreditsEntry {
    let signedIn = TokenStorage().getAccessToken() != nil
    return CreditsEntry(
      date: .now,
      snapshot: signedIn ? CreditSummarySnapshotStore().snapshot : nil,
      signInRequired: !signedIn
    )
  }
}

struct BuddyCreditsWidgetEntryView: View {
  @Environment(\.widgetFamily) private var family
  let entry: CreditsEntry

  var body: some View {
    Group {
      switch family {
      case .systemSmall:
        CreditsSmallWidgetView(entry: entry)
      case .accessoryInline:
        CreditsInlineWidgetView(entry: entry)
      case .accessoryCircular:
        CreditsCircularWidgetView(entry: entry)
      case .accessoryRectangular:
        CreditsRectangularWidgetView(entry: entry)
      default:
        CreditsMediumWidgetView(entry: entry)
      }
    }
    // No Credits deep link yet; the Timetable screen's credits card opens it.
    .widgetURL(URL(string: "sparcsapp://timetable"))
  }
}

struct BuddyCreditsWidget: Widget {
  var body: some WidgetConfiguration {
    StaticConfiguration(kind: CreditSummarySnapshotStore.widgetKind, provider: CreditsProvider()) { entry in
      BuddyCreditsWidgetEntryView(entry: entry)
        .containerBackground(.fill.tertiary, for: .widget)
    }
    .supportedFamilies([.systemSmall, .systemMedium, .accessoryInline, .accessoryCircular, .accessoryRectangular])
    .configurationDisplayName("Credits")
    .description("Your GPA and progress towards graduation.")
  }
}

#Preview(as: .systemMedium) {
  BuddyCreditsWidget()
} timeline: {
  CreditsEntry.sample
  CreditsEntry(date: .now, snapshot: CreditSummarySnapshot(gpa: 3.03, earnedCredits: 140, graduationCredits: 138), signInRequired: false)
  CreditsEntry(date: .now, snapshot: nil, signInRequired: false)
  CreditsEntry(date: .now, snapshot: nil, signInRequired: true)
}

#Preview(as: .systemSmall) {
  BuddyCreditsWidget()
} timeline: {
  CreditsEntry.sample
  CreditsEntry(date: .now, snapshot: nil, signInRequired: false)
}

#Preview(as: .accessoryRectangular) {
  BuddyCreditsWidget()
} timeline: {
  CreditsEntry.sample
  CreditsEntry(date: .now, snapshot: nil, signInRequired: false)
}

#Preview(as: .accessoryCircular) {
  BuddyCreditsWidget()
} timeline: {
  CreditsEntry.sample
}

#Preview(as: .accessoryInline) {
  BuddyCreditsWidget()
} timeline: {
  CreditsEntry.sample
}
