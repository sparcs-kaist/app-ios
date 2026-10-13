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
            // An activity that starts already stale is never shown, so only future begins count.
            content: ActivityContent(state: state, staleDate: state.current.map(\.beginDate).flatMap { $0 > .now ? $0 : nil })
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
        alertConfiguration: AlertConfiguration(title: "System Programming", body: "E3 304 · Starts in 20 minutes", sound: .default)
      )
      UIApplication.shared.endBackgroundTask(backgroundTask)
    }
  }

  static func state(for scenario: String, now date: Date = .now) -> TimetableActivityAttributes.ContentState? {
    let now = Int(date.timeIntervalSince1970)
    let korean = Locale.current.language.languageCode == .korean
    let systems = korean ? "시스템 프로그래밍" : "System Programming"
    let problemSolving = korean ? "문제해결기법" : "Problem Solving"

    func systemsClass(begin: Int) -> TimetableActivityAttributes.Item {
      .init(title: systems, buildingCode: "E3", buildingName: korean ? "(E3)정보전자공학동" : "Information & Electronics Building",
            room: "304", kind: .lecture, colorID: 10, begin: begin, end: begin + 75 * 60)
    }
    func problemSolvingClass(begin: Int) -> TimetableActivityAttributes.Item {
      .init(title: problemSolving, buildingCode: "W3-1", buildingName: "W3-1", room: "1501", kind: .lecture,
            colorID: 5, begin: begin, end: begin + 75 * 60)
    }
    func problemSolvingNext(begin: Int) -> TimetableActivityAttributes.NextItem {
      .init(title: problemSolving, buildingCode: "W3-1", buildingName: "W3-1", room: "1501", kind: .lecture,
            colorID: 5, begin: begin)
    }

    switch scenario {
    case "upcoming":
      let begin = now + 20 * 60
      return .init(phase: .upcoming, current: systemsClass(begin: begin), next: problemSolvingNext(begin: begin + 90 * 60))
    case "soon":
      // Starts a few seconds from now, to watch the switch at class start happen on its own.
      let begin = now + 20
      return .init(phase: .upcoming, current: systemsClass(begin: begin), next: problemSolvingNext(begin: begin + 90 * 60))
    case "inProgress":
      let begin = now - 30 * 60
      return .init(phase: .upcoming, current: systemsClass(begin: begin), next: problemSolvingNext(begin: begin + 90 * 60))
    case "ending":
      let begin = now - 60 * 60
      return .init(phase: .upcoming, current: systemsClass(begin: begin), next: problemSolvingNext(begin: begin + 90 * 60))
    case "last":
      return .init(phase: .upcoming, current: problemSolvingClass(begin: now - 30 * 60), next: nil)
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
      return .init(phase: .done, current: problemSolvingClass(begin: now - 77 * 60), next: nil)
    default:
      return nil
    }
  }
}
#endif
