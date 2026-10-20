//
//  TimetableOnboarding.swift
//  BuddyFeature
//
//  Created by Soongyu Kwon on 19/10/2026.
//

import Foundation
import TipKit
import BuddyFeatureShared

/// The tips that teach adding a lecture, shown one after another across the timetable, lecture
/// search and lecture details, in the order a new user goes through them. Each tip shows only on
/// its own step, and finishing a step, by doing what the tip says, closing it or skipping it where
/// it does not apply, moves on to the next.
///
/// The state is kept in user defaults and copied into TipKit parameters for the tips' rules. A
/// parameter read soon after launch gives its default rather than its stored value, so reading
/// the parameters back would start the onboarding over on every launch.
enum TimetableOnboarding {
  enum Step: Int, Comparable {
    /// My Table is read-only: create or duplicate a table. `StartEditingTip`.
    case startEditing
    /// Adding starts from the toolbar's add button. `AddEventTip`.
    case addButton
    /// The full-screen search's timetable preview can be resized. `ResizePreviewTip`.
    case resizePreview
    /// The preview can be hidden and shown again. `TogglePreviewTip`.
    case togglePreview
    /// Swipe a result or tap + in its details, until the first lecture is added. `SwipeToAddTip`,
    /// `AddFromDetailTip`.
    case addLecture
    case done

    static func < (lhs: Step, rhs: Step) -> Bool { lhs.rawValue < rhs.rawValue }
  }

  /// The current step's raw value, for the rules, which compare plain values.
  @Parameter static var step: Int = Step.startEditing.rawValue
  /// Set once the first timetable list has loaded and been checked for tables the user made
  /// before the onboarding existed. The timetable's tips wait for it, so they don't show to such
  /// a user before the check skips them.
  @Parameter static var hasCheckedForExistingTables: Bool = false

  static var current: Step {
    get {
      restoreParameters
      return Step(rawValue: defaults.integer(forKey: Keys.step)) ?? .done
    }
    set {
      defaults.set(newValue.rawValue, forKey: Keys.step)
      step = newValue.rawValue
    }
  }

  private static var hasChecked: Bool {
    get { defaults.bool(forKey: Keys.hasChecked) }
    set {
      defaults.set(newValue, forKey: Keys.hasChecked)
      hasCheckedForExistingTables = newValue
    }
  }

  /// For a user who already had tables: they know how to add, so the onboarding ends after the
  /// preview's tips, which are new to everyone.
  private static var skipsAddLecture: Bool {
    get { defaults.bool(forKey: Keys.skipsAddLecture) }
    set { defaults.set(newValue, forKey: Keys.skipsAddLecture) }
  }

  /// Copies the stored state into the parameters, once a launch.
  private static let restoreParameters: Void = {
    step = defaults.integer(forKey: Keys.step)
    hasCheckedForExistingTables = defaults.bool(forKey: Keys.hasChecked)
  }()

  private static var defaults: UserDefaults { .standard }

  private enum Keys {
    static let step = BuddyTips.onboardingKeyPrefix + "timetable.step"
    static let hasChecked = BuddyTips.onboardingKeyPrefix + "timetable.hasCheckedForExistingTables"
    static let skipsAddLecture = BuddyTips.onboardingKeyPrefix + "timetable.skipsAddLecture"
  }

  /// Rules that show a tip only on its step, with the timetable's tips also waiting for the check
  /// for existing tables.
  static func rules(for step: Step) -> [Tips.Rule] {
    let value = step.rawValue
    return [
      #Rule(Self.$step) { $0 == value },
      #Rule(Self.$hasCheckedForExistingTables) { $0 == true },
    ]
  }

  /// Moves on from `finished` if it is the current step. Doing what a tip says, closing it and
  /// skipping it all end up here, so calling it more than once for a step does nothing.
  static func complete(_ finished: Step) {
    guard current == finished else { return }
    let next: Step = switch finished {
    case .startEditing: .addButton
    case .addButton: .resizePreview
    case .resizePreview: .togglePreview
    case .togglePreview: skipsAddLecture ? .done : .addLecture
    case .addLecture, .done: .done
    }
    current = next
  }

  /// Skips the preview's steps where the search has no preview: the sheet, and a screen wide
  /// enough to show the timetable beside the results.
  static func skipPreviewSteps() {
    complete(.resizePreview)
    complete(.togglePreview)
  }

  /// Checks the first timetable list to load for tables made before the onboarding existed. Such
  /// a user skips straight to the preview's tips. A reset from the debug settings starts over as
  /// for a new user instead.
  static func checkForExistingTables(hasTables: Bool) {
    guard !hasChecked else { return }
    let replays = BuddyTips.consumeOnboardingReplay()
    if hasTables && !replays && current < .resizePreview {
      skipsAddLecture = true
      current = .resizePreview
    }
    hasChecked = true
  }

  /// The first lecture added, from anywhere, ends the onboarding.
  static func lectureAdded() {
    complete(.addLecture)
  }

  /// Moves on when a step's tip is closed with its close button, which tells the app nothing
  /// otherwise. Everything else that invalidates a step's tip also completes the step itself, as
  /// TipKit doesn't report a tip that was invalidated before this started watching it. Runs for as
  /// long as the calling task.
  static func observeTips() async {
    restoreParameters
    await withDiscardingTaskGroup { group in
      group.addTask { await completeOnInvalidation(StartEditingTip(), .startEditing) }
      group.addTask { await completeOnInvalidation(AddEventTip(), .addButton) }
      group.addTask { await completeOnInvalidation(ResizePreviewTip(), .resizePreview) }
      group.addTask { await completeOnInvalidation(TogglePreviewTip(), .togglePreview) }
    }
  }

  private static func completeOnInvalidation(_ tip: some Tip, _ step: Step) async {
    if case .invalidated = tip.status {
      complete(step)
    }
    for await status in tip.statusUpdates {
      if case .invalidated = status {
        complete(step)
      }
    }
  }
}
