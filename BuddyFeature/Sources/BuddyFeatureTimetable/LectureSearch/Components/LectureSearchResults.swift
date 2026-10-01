//
//  LectureSearchResults.swift
//  BuddyFeature
//
//  Created by Soongyu Kwon on 20/09/2025.
//

import SwiftUI
import BuddyDomain

/// A screen pushed from the lecture search results.
enum LectureSearchRoute: Hashable {
  case lecture(Lecture)
  case course(id: Int, name: String)

  var lecture: Lecture? {
    if case .lecture(let lecture) = self { lecture } else { nil }
  }
}

/// The grouped list of courses and their lectures in the search sheet. Each lecture is one
/// professor's section, so its row carries that section's schedule and review ratings.
struct LectureSearchResults: View {
  let courses: [CourseLecture]

  var body: some View {
    ForEach(courses) { course in
      Section {
        // The course page shows every semester it was offered and who taught it.
        NavigationLink(value: LectureSearchRoute.course(id: course.id, name: course.name)) {
          CourseHeader(course: course)
        }
        ForEach(course.lectures) { lecture in
          NavigationLink(value: LectureSearchRoute.lecture(lecture)) {
            LectureRow(lecture: lecture)
          }
        }
      }
    }
  }
}

private struct CourseHeader: View {
  let course: CourseLecture

  var body: some View {
    VStack(alignment: .leading, spacing: 4) {
      HStack(alignment: .firstTextBaseline, spacing: 8) {
        Text(course.name)
          .font(.headline)
          .lineLimit(2)
          .multilineTextAlignment(.leading)

        // The server marks a course you have taken in any earlier semester.
        if course.completed {
          Spacer(minLength: 0)
          takenBadge
        }
      }

      Text(details.joined(separator: " · "))
        .font(.footnote)
        .foregroundStyle(.secondary)
        .lineLimit(1)
    }
  }

  private var takenBadge: some View {
    // Not a Label: list rows reduce a Label to its icon.
    HStack(spacing: 3) {
      Image(systemName: "checkmark.circle.fill")
      Text("Taken", bundle: .module)
    }
    .font(.caption.weight(.semibold))
    .foregroundStyle(.tint)
    .padding(.horizontal, 8)
    .padding(.vertical, 3)
    .background(.tint.quaternary, in: .capsule)
    .fixedSize()
  }

  private var details: [String] {
    var details = [course.code, course.type.displayName.localized()]
    if let lecture = course.lectures.first {
      if lecture.credit > 0 {
        details.append(String(localized: "\(lecture.credit) credits", bundle: .module))
      } else if lecture.creditAU > 0 {
        details.append(String(localized: "\(lecture.creditAU) AU", bundle: .module))
      }
    }
    return details
  }
}

private struct LectureRow: View {
  let lecture: Lecture

  var body: some View {
    HStack(alignment: .top, spacing: 12) {
      if !lecture.section.isEmpty {
        Text(lecture.section)
          .font(.subheadline.weight(.semibold))
          .fontDesign(.rounded)
          .foregroundStyle(.secondary)
          .frame(minWidth: 26, minHeight: 26)
          .background(.fill.tertiary, in: .rect(cornerRadius: 8))
      }

      VStack(alignment: .leading, spacing: 6) {
        HStack(alignment: .firstTextBaseline) {
          Text(professors)
            .font(.body.weight(.medium))
            .lineLimit(1)
          Spacer(minLength: 8)
          if lecture.capacity > 0 {
            enrollment
          }
        }

        Text(schedule)
          .font(.footnote)
          .foregroundStyle(.secondary)
          .lineLimit(2)

        ratings
      }
    }
    .padding(.vertical, 2)
  }

  private var professors: String {
    let names = lecture.professors.map(\.name)
    return names.isEmpty
      ? String(localized: "Unknown", bundle: .module)
      : names.formatted(.list(type: .and, width: .narrow))
  }

  /// Class times grouped by time slot, such as "Mon, Wed 10:30-11:45".
  private var schedule: String {
    guard !lecture.classes.isEmpty else {
      return String(localized: "No class time", bundle: .module)
    }
    var slots: [(time: String, days: [DayType])] = []
    for lectureClass in lecture.classes.sorted(by: { ($0.day, $0.begin) < ($1.day, $1.begin) }) {
      if let index = slots.firstIndex(where: { $0.time == lectureClass.description }) {
        slots[index].days.append(lectureClass.day)
      } else {
        slots.append((lectureClass.description, [lectureClass.day]))
      }
    }
    return slots
      .map { "\($0.days.map(\.stringValue).joined(separator: ", ")) \($0.time)" }
      .joined(separator: " · ")
  }

  private var enrollment: some View {
    HStack(spacing: 3) {
      Image(systemName: "person.2.fill")
      Text(verbatim: "\(lecture.enrolledCount)/\(lecture.capacity)")
        .monospacedDigit()
    }
    .font(.caption)
    .foregroundStyle(lecture.enrolledCount > lecture.capacity ? AnyShapeStyle(.orange) : AnyShapeStyle(.secondary))
    .accessibilityElement(children: .ignore)
    .accessibilityLabel(String(localized: "\(lecture.enrolledCount) of \(lecture.capacity) enrolled", bundle: .module))
  }

  @ViewBuilder
  private var ratings: some View {
    // The server reports 0 for every average until the section has a review.
    if lecture.grade == 0 && lecture.load == 0 && lecture.speech == 0 {
      Text("No ratings yet", bundle: .module)
        .font(.caption)
        .foregroundStyle(.tertiary)
    } else {
      HStack(spacing: 14) {
        RatingLabel(title: String(localized: "Grade", bundle: .module), letter: lecture.gradeLetter)
        RatingLabel(title: String(localized: "Load", bundle: .module), letter: lecture.loadLetter)
        RatingLabel(title: String(localized: "Speech", bundle: .module), letter: lecture.speechLetter)
      }
    }
  }
}

/// One review average, with its letter tinted so good and bad sections stand out at a glance.
private struct RatingLabel: View {
  let title: String
  let letter: String

  var body: some View {
    HStack(alignment: .firstTextBaseline, spacing: 4) {
      Text(title)
        .font(.caption)
        .foregroundStyle(.secondary)
      Text(letter)
        .font(.subheadline.weight(.semibold))
        .fontDesign(.rounded)
        .foregroundStyle(tint)
    }
    .accessibilityElement(children: .combine)
  }

  /// Every metric reads the same way round: A is the best (high grades, light load, clear speech).
  private var tint: Color {
    switch letter.first {
    case "A": .green
    case "B": .teal
    case "C": .orange
    case "D", "F": .red
    default: .secondary
    }
  }
}
