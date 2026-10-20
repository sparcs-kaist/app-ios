//
//  TimetableTips.swift
//  BuddyFeature
//
//  Created by Soongyu Kwon on 19/10/2026.
//

import SwiftUI
import TipKit
import AppIntents

// MARK: - Onboarding

/// On My Table, which is read-only: make a table to edit. Inline, with the actions themselves.
struct StartEditingTip: Tip {
  static let newTable = "newTable"
  static let duplicateMyTable = "duplicateMyTable"

  var title: Text { Text("Make Your Own Table", bundle: .module) }
  var message: Text? { Text("My Table is read-only. Create a table, or duplicate My Table, to start editing.", bundle: .module) }
  var image: Image? { Image(systemName: "square.and.pencil") }
  var actions: [Action] {
    [
      Action(id: Self.newTable, title: String(localized: "New Table", bundle: .module)),
      Action(id: Self.duplicateMyTable, title: String(localized: "Duplicate My Table", bundle: .module)),
    ]
  }
  var rules: [Rule] { TimetableOnboarding.rules(for: .startEditing) }
  var options: [any TipOption] { [Tips.IgnoresDisplayFrequency(true)] }
}

/// Under the table selector, once an editable table is selected. Inline, as a popover on a toolbar
/// item doesn't show; the message shows the button's symbol instead.
struct AddEventTip: Tip {
  var title: Text { Text("Add Lectures and Activities", bundle: .module) }
  var message: Text? { Text("Tap \(Image(systemName: "square.badge.plus")) to search for lectures or create your own activities.", bundle: .module) }
  var image: Image? { Image(systemName: "square.badge.plus") }
  var rules: [Rule] { TimetableOnboarding.rules(for: .addButton) }
  var options: [any TipOption] { [Tips.IgnoresDisplayFrequency(true)] }
}

/// On the full-screen search's timetable preview, at its resize handle.
struct ResizePreviewTip: Tip {
  var title: Text { Text("Resize the Timetable", bundle: .module) }
  var message: Text? { Text("Drag the handle to make it bigger or smaller.", bundle: .module) }
  var image: Image? { Image(systemName: "arrow.up.and.down") }
  var rules: [Rule] { TimetableOnboarding.rules(for: .resizePreview) }
  var options: [any TipOption] { [Tips.IgnoresDisplayFrequency(true)] }
}

/// Above the full-screen search's results, pointing at its Timetable button by its symbol.
struct TogglePreviewTip: Tip {
  var title: Text { Text("Show or Hide the Timetable", bundle: .module) }
  var message: Text? { Text("Tap \(Image(systemName: "calendar")) to hide it and see more results, and again to bring it back.", bundle: .module) }
  var image: Image? { Image(systemName: "calendar") }
  var rules: [Rule] { TimetableOnboarding.rules(for: .togglePreview) }
  var options: [any TipOption] { [Tips.IgnoresDisplayFrequency(true)] }
}

/// Above the search results. The onboarding's last step, with `AddFromDetailTip`: whichever the
/// user meets first teaches adding, and the other follows later as an ordinary tip.
struct SwipeToAddTip: Tip {
  var title: Text { Text("Swipe to Add", bundle: .module) }
  var message: Text? { Text("Swipe left on a lecture to add it, or right to save it to your wishlist.", bundle: .module) }
  var image: Image? { Image(systemName: "hand.draw") }
  var rules: [Rule] { TimetableOnboarding.addLectureRules }
  var options: [any TipOption] { TimetableOnboarding.addLectureOptions }
}

/// At the top of a lecture opened from search, pointing at its Add button by its symbol.
struct AddFromDetailTip: Tip {
  let timetableName: String

  var id: String { "AddFromDetailTip" }
  var title: Text { Text("Add This Lecture", bundle: .module) }
  var message: Text? { Text("Tap \(Image(systemName: "plus")) to add it to “\(timetableName)”.", bundle: .module) }
  var image: Image? { Image(systemName: "plus.circle") }
  var rules: [Rule] { TimetableOnboarding.addLectureRules }
  var options: [any TipOption] { TimetableOnboarding.addLectureOptions }
}

extension TimetableOnboarding {
  /// From the onboarding's last step on: the add tips stay as ordinary tips once it is over.
  static var addLectureRules: [Tips.Rule] {
    let value = Step.addLecture.rawValue
    return [#Rule(Self.$step) { $0 >= value }]
  }

  /// Shown at once while they are part of the onboarding, and no more than the usual one new tip
  /// a day after.
  static var addLectureOptions: [any TipOption] {
    [Tips.IgnoresDisplayFrequency(current == .addLecture)]
  }

  /// Once the onboarding is over.
  static var afterOnboardingRules: [Tips.Rule] {
    let value = Step.done.rawValue
    return [#Rule(Self.$step) { $0 == value }]
  }
}

// MARK: - After onboarding

/// Above the search results, after `SwipeToAddTip`, once lectures have been opened by tapping.
struct PeekLectureTip: Tip {
  static let lectureOpened = Tips.Event(id: "lectureSearch.lectureOpened")

  var title: Text { Text("Peek at a Lecture", bundle: .module) }
  var message: Text? { Text("Touch and hold a lecture to preview its details.", bundle: .module) }
  var image: Image? { Image(systemName: "hand.tap") }
  var options: [any TipOption] { [Tips.MaxDisplayCount(3)] }
  var rules: [Rule] {
    TimetableOnboarding.afterOnboardingRules + [
      #Rule(Self.lectureOpened) { $0.donations.count >= 2 },
    ]
  }
}

/// On the table selector, once the timetable is worth sharing.
struct ShareTimetableTip: Tip {
  var title: Text { Text("Share Your Timetable", bundle: .module) }
  var message: Text? { Text("Share it as an image from this menu.", bundle: .module) }
  var image: Image? { Image(systemName: "square.and.arrow.up") }
  var options: [any TipOption] { [Tips.MaxDisplayCount(3)] }
  var rules: [Rule] { TimetableOnboarding.afterOnboardingRules }
}

/// Under the timetable, after `ShareTimetableTip`. Shown as a `SiriTipView` for the app's Next
/// Class shortcut, which this tip only decides when to show.
struct AskSiriTip: Tip {
  var title: Text { Text("Ask Siri", bundle: .module) }
  var rules: [Rule] { TimetableOnboarding.afterOnboardingRules }
}

/// On the More menu of the first review long enough to summarise, which holds Summarise.
struct SummariseReviewTip: Tip {
  var title: Text { Text("Summarise Long Reviews", bundle: .module) }
  var message: Text? { Text("Summarise a long review from this menu.", bundle: .module) }
  var image: Image? { Image(systemName: "text.append") }
  var options: [any TipOption] { [Tips.MaxDisplayCount(3)] }
}

/// At the top of a new activity, for the second activity onwards.
struct QuickFillTip: Tip {
  static let activityCreationOpened = Tips.Event(id: "activityCreation.opened")

  var title: Text { Text("Fill In from a Description", bundle: .module) }
  var message: Text? { Text("Describe your activity, and Quick Fill adds its title, place and times.", bundle: .module) }
  var image: Image? { Image(systemName: "wand.and.sparkles") }
  var options: [any TipOption] { [Tips.MaxDisplayCount(3)] }
  var rules: [Rule] {
    [#Rule(Self.activityCreationOpened) { $0.donations.count >= 2 }]
  }
}

extension EnvironmentValues {
  /// The app's Next Class shortcut, which `AskSiriTip` suggests. Set by the app, which defines
  /// its intents; the tip is left out without it.
  @Entry public var timetableSiriTipIntent: (any AppIntent)? = nil
}
