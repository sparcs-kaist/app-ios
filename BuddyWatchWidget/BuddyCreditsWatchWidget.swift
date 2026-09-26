//
//  BuddyCreditsWatchWidget.swift
//  BuddyWatchWidget
//
//  Created by Soongyu Kwon on 26/09/2026.
//

import WidgetKit
import SwiftUI
import BuddyDomain
import BuddySharedUI

/// Reads the Credits totals the iPhone app sent over the session bridge; the watch
/// never computes them. The bridge reloads this widget when new totals arrive.
struct CreditsWatchProvider: TimelineProvider {
  func placeholder(in context: Context) -> CreditsEntry {
    .sample
  }

  func getSnapshot(in context: Context, completion: @escaping (CreditsEntry) -> Void) {
    let entry = currentEntry()
    completion(context.isPreview && entry.snapshot == nil ? .sample : entry)
  }

  func getTimeline(in context: Context, completion: @escaping (Timeline<CreditsEntry>) -> Void) {
    completion(Timeline(entries: [currentEntry()], policy: .after(.now.addingTimeInterval(60 * 60 * 12))))
  }

  /// The phone clears the totals on sign-out, so no totals covers both "signed
  /// out" and "not computed yet"; the entry shows the Open Credits prompt.
  private func currentEntry() -> CreditsEntry {
    CreditsEntry(date: .now, snapshot: CreditSummarySnapshotStore().snapshot, signInRequired: false)
  }
}

struct BuddyCreditsWatchWidgetEntryView: View {
  @Environment(\.widgetFamily) private var family
  let entry: CreditsEntry

  var body: some View {
    switch family {
    case .accessoryCorner:
      CreditsCornerWidgetView(entry: entry)
    case .accessoryInline:
      CreditsInlineWidgetView(entry: entry)
    case .accessoryRectangular:
      CreditsRectangularWidgetView(entry: entry)
    default:
      CreditsCircularWidgetView(entry: entry)
    }
  }
}

struct BuddyCreditsWatchWidget: Widget {
  var body: some WidgetConfiguration {
    StaticConfiguration(kind: CreditSummarySnapshotStore.widgetKind, provider: CreditsWatchProvider()) { entry in
      BuddyCreditsWatchWidgetEntryView(entry: entry)
        .containerBackground(.fill.tertiary, for: .widget)
    }
    .supportedFamilies([.accessoryCircular, .accessoryRectangular, .accessoryInline, .accessoryCorner])
    .configurationDisplayName("Credits")
    .description("Your progress towards graduation.")
  }
}

#Preview(as: .accessoryRectangular) {
  BuddyCreditsWatchWidget()
} timeline: {
  CreditsEntry.sample
  CreditsEntry(date: .now, snapshot: nil, signInRequired: false)
}

#Preview(as: .accessoryCircular) {
  BuddyCreditsWatchWidget()
} timeline: {
  CreditsEntry.sample
}

#Preview(as: .accessoryCorner) {
  BuddyCreditsWatchWidget()
} timeline: {
  CreditsEntry.sample
}

#Preview(as: .accessoryInline) {
  BuddyCreditsWatchWidget()
} timeline: {
  CreditsEntry.sample
}
