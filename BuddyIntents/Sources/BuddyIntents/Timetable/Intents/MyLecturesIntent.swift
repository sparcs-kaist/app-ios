//
//  MyLecturesIntent.swift
//  BuddyIntents
//

import AppIntents
import SwiftUI
import BuddyDomain
import BuddyDataCore

/// "What are my lectures this semester?" Lists the active timetable's lectures.
///
/// A plain intent with fixed phrases, so it works without Siri AI: on iOS 26, in
/// the EU, and in Korean before iOS 27.2.
public struct MyLecturesIntent: AppIntent {
  public static let title: LocalizedStringResource = "Get My Lectures"
  public static let description = IntentDescription(
    "Lists the lectures in your timetable this semester.",
    categoryName: "Buddy"
  )
  public static let supportedModes: IntentModes = [.background]

  public init() {}

  public func perform() async throws -> some ReturnsValue<[LectureEntity]> & ProvidesDialog & ShowsSnippetView {
    guard let active = await ActiveTimetableResolver.app()?.resolve() else {
      return .result(
        value: [],
        dialog: "Buddy couldn't load your timetable. Open Buddy and try again.",
        view: MyLecturesSnippetView(lectures: [], semester: nil)
      )
    }

    let lectures = LectureEntity.all(for: active)
    let semester = active.semester.description
    guard !lectures.isEmpty else {
      return .result(
        value: [],
        dialog: "There are no lectures in your timetable for \(semester).",
        view: MyLecturesSnippetView(lectures: [], semester: semester)
      )
    }

    let names = lectures.map(\.name).formatted(.list(type: .and))
    return .result(
      value: lectures,
      dialog: "Your lectures for \(semester), \(active.timetable.credits) credits in total: \(names).",
      view: MyLecturesSnippetView(lectures: lectures, semester: semester)
    )
  }
}

struct MyLecturesSnippetView: View {
  let lectures: [LectureEntity]
  let semester: String?

  var body: some View {
    VStack(alignment: .leading, spacing: 8) {
      if let semester {
        Text(semester)
          .font(.caption)
          .fontWeight(.semibold)
          .foregroundStyle(.secondary)
      }
      ForEach(lectures, id: \.id) { lecture in
        VStack(alignment: .leading, spacing: 2) {
          Text(lecture.name)
            .fontWeight(.semibold)
            .lineLimit(1)
          Text(lecture.schedule)
            .font(.caption)
            .foregroundStyle(.secondary)
            .lineLimit(2)
        }
      }
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .padding()
  }
}
