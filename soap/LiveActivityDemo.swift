//
//  LiveActivityDemo.swift
//  soap
//
//  Created by Soongyu Kwon on 13/10/2026.
//

#if DEBUG
import ActivityKit
import UIKit
import BuddyLiveActivityUI

/// Starts a sample class Live Activity for design review, e.g.
/// `xcrun simctl launch booted org.sparcs.soap -LiveActivityDemo inProgress`.
///
/// `-LiveActivityDemoAlertAfter <seconds>` sends an alert update after a delay, which shows the
/// expanded Dynamic Island once the app is in the background.
enum LiveActivityDemo {
  @MainActor
  static func runIfRequested() {
    let defaults = UserDefaults.standard
    guard let scenario = defaults.string(forKey: "LiveActivityDemo") else { return }
    let alertDelay = defaults.double(forKey: "LiveActivityDemoAlertAfter")

    Task {
      for activity in Activity<TimetableActivityAttributes>.activities {
        await activity.end(nil, dismissalPolicy: .immediate)
      }

      let states = scenario.split(separator: ",").compactMap { state(for: String($0)) }
      var started: [Activity<TimetableActivityAttributes>] = []
      for (index, state) in states.enumerated() {
        do {
          let activity = try Activity.request(
            attributes: TimetableActivityAttributes(sessionDate: "2026-10-13", sessionNo: index),
            content: ActivityContent(state: state, staleDate: state.current?.beginDate)
          )
          started.append(activity)
        } catch {
          logger.error("Live Activity demo failed: \(error.localizedDescription, privacy: .public)")
        }
      }

      guard alertDelay > 0, let activity = started.first else { return }
      let backgroundTask = UIApplication.shared.beginBackgroundTask()
      try? await Task.sleep(for: .seconds(alertDelay))
      await activity.update(
        activity.content,
        alertConfiguration: AlertConfiguration(title: "Physics I", body: "Starts in 12 minutes", sound: .default)
      )
      UIApplication.shared.endBackgroundTask(backgroundTask)
    }
  }

  static func state(for scenario: String, now date: Date = .now) -> TimetableActivityAttributes.ContentState? {
    let now = Int(date.timeIntervalSince1970)
    let korean = Locale.current.language.languageCode == .korean
    let physics = korean ? "일반물리학 I" : "General Physics I"
    let calculus = korean ? "미적분학 I" : "Calculus I"
    // OTL's Korean names carry the code in brackets; the views strip it.
    let e11 = korean ? "(E11)창의학습관" : "Creative Learning Building"
    let e61 = korean ? "(E6-1)자연과학동" : "Natural Science Building"

    func physicsClass(begin: Int) -> TimetableActivityAttributes.Item {
      .init(title: physics, buildingCode: "E11", buildingName: e11, room: "101", kind: .lecture,
            colorID: 1, begin: begin, end: begin + 75 * 60)
    }
    func calculusClass(begin: Int) -> TimetableActivityAttributes.Item {
      .init(title: calculus, buildingCode: "E6-1", buildingName: e61, room: "1501", kind: .lecture,
            colorID: 2, begin: begin, end: begin + 75 * 60)
    }
    func calculusNext(begin: Int) -> TimetableActivityAttributes.NextItem {
      .init(title: calculus, buildingCode: "E6-1", kind: .lecture, colorID: 2, begin: begin)
    }

    switch scenario {
    case "upcoming":
      let begin = now + 12 * 60 + 4
      return .init(phase: .upcoming, current: physicsClass(begin: begin), next: calculusNext(begin: begin + 4 * 3600))
    case "inProgress":
      let begin = now - 33 * 60 - 48
      return .init(phase: .upcoming, current: physicsClass(begin: begin), next: calculusNext(begin: begin + 4 * 3600))
    case "last":
      return .init(phase: .upcoming, current: calculusClass(begin: now - 21 * 60), next: nil)
    case "activity":
      let begin = now + 8 * 60
      return .init(
        phase: .upcoming,
        current: .init(title: korean ? "SPARCS 정기 회의" : "SPARCS Meeting", buildingCode: nil,
                       buildingName: korean ? "SPARCS 동아리방" : "SPARCS Club Room", room: nil,
                       kind: .activity, colorID: 9, begin: begin, end: begin + 60 * 60),
        next: nil
      )
    case "done":
      return .init(phase: .done, current: calculusClass(begin: now - 77 * 60), next: nil)
    default:
      return nil
    }
  }
}
#endif
