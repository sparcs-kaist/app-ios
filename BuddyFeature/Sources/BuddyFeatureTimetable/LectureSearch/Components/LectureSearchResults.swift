//
//  LectureSearchResults.swift
//  BuddyFeature
//
//  Created by Soongyu Kwon on 20/09/2025.
//

import SwiftUI
import BuddyDomain
import BuddyFeatureShared

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
  let timetable: Timetable?
  /// Opening a lecture also previews it, so it goes through the search view rather than a link.
  let onOpenLecture: (Lecture) -> Void
  let onOpenCourse: (_ id: Int, _ name: String) -> Void
  let onAddLecture: (Lecture) -> Void
  let wishlistedLectureIDs: Set<Int>
  let onToggleWishlist: (Lecture) -> Void
  /// The wishlist endpoint's ratings are unreliable, so its rows leave them out.
  var showsRatings: Bool = true
  /// The wishlist heading over the first course, when these results are the wishlist.
  var wishlistHeader: String? = nil

  var body: some View {
    ForEach(courses) { course in
      Section {
        // The course page shows every semester it was offered and who taught it.
        NavigationLink(value: LectureSearchRoute.course(id: course.id, name: course.name)) {
          CourseHeader(course: course)
        }
        ForEach(course.lectures) { lecture in
          let conflicts = timetable?.conflicts(with: lecture) ?? []
          let isAdded = timetable?.contains(lecture) ?? false
          let isWishlisted = wishlistedLectureIDs.contains(lecture.id)
          HStack(spacing: 10) {
            Button {
              onOpenLecture(lecture)
            } label: {
              LectureRow(lecture: lecture, conflicts: conflicts, isAdded: isAdded, showsRatings: showsRatings)
                .contentShape(.rect)
            }
            .buttonStyle(.plain)

            // The heart and the enrollment stack as the row's trailing column; tapping
            // anywhere else opens the lecture.
            VStack(alignment: .trailing, spacing: 2) {
              WishlistButton(isWishlisted: isWishlisted) {
                onToggleWishlist(lecture)
              }
              if lecture.capacity > 0 {
                EnrollmentLabel(lecture: lecture)
              }
            }
          }
          .swipeActions(edge: .leading, allowsFullSwipe: true) {
            Button {
              onToggleWishlist(lecture)
            } label: {
              Label(
                isWishlisted
                  ? String(localized: "Remove from Wishlist", bundle: .module)
                  : String(localized: "Add to Wishlist", bundle: .module),
                systemImage: isWishlisted ? "heart.slash" : "heart"
              )
            }
            .tint(.pink)
          }
          .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            // Only offered when it can succeed, like the Add button in the details.
            if !isAdded && conflicts.isEmpty {
              Button {
                onAddLecture(lecture)
              } label: {
                Label(String(localized: "Add to Timetable", bundle: .module), systemImage: "plus")
              }
              .tint(.accentColor)
            }
          }
          // A long press peeks at the lecture's details without opening it.
          .contextMenu {
            lectureActions(lecture, conflicts: conflicts, isAdded: isAdded, isWishlisted: isWishlisted)
          } preview: {
            // In a stack so the preview carries the lecture's name as its title.
            NavigationStack {
              LectureDetailView(
                lecture: lecture,
                onAdd: nil,
                conflicts: conflicts,
                isAdded: isAdded,
                lectureClass: lecture.classes.first
              )
            }
            .frame(width: 380, height: 560)
          }
        }
      } header: {
        if course.id == courses.first?.id, let wishlistHeader {
          Label {
            Text(wishlistHeader)
          } icon: {
            Image(systemName: "heart.fill")
              .foregroundStyle(.pink)
          }
        }
      }
      // The system's title-style header, in primary text like the course names below it.
      .headerProminence(.increased)
    }
  }

  @ViewBuilder
  private func lectureActions(_ lecture: Lecture, conflicts: [String], isAdded: Bool, isWishlisted: Bool) -> some View {
    Button(String(localized: "Open", bundle: .module), systemImage: "arrow.up.right") {
      onOpenLecture(lecture)
    }
    Button(String(localized: "View Course", bundle: .module), systemImage: "book.closed") {
      onOpenCourse(lecture.courseID, lecture.name)
    }
    Section {
      Button(
        isWishlisted
          ? String(localized: "Remove from Wishlist", bundle: .module)
          : String(localized: "Add to Wishlist", bundle: .module),
        systemImage: isWishlisted ? "heart.slash" : "heart"
      ) {
        onToggleWishlist(lecture)
      }
      if isAdded {
        Button(String(localized: "Added", bundle: .module), systemImage: "checkmark") { }
          .disabled(true)
      } else {
        // Same rule as the detail's Add button: an overlapping lecture cannot be added.
        Button {
          onAddLecture(lecture)
        } label: {
          Label(String(localized: "Add to Timetable", bundle: .module), systemImage: "plus")
          if !conflicts.isEmpty {
            Text("Overlaps with \(conflicts.formatted(.list(type: .and)))", bundle: .module)
          }
        }
        .disabled(!conflicts.isEmpty)
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
          TakenBadge()
        }
      }

      Text(details.joined(separator: " · "))
        .font(.footnote)
        .foregroundStyle(.secondary)
        .lineLimit(1)
    }
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
  let conflicts: [String]
  let isAdded: Bool
  var showsRatings: Bool = true

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
        Text(professors)
          .font(.body.weight(.medium))
          .lineLimit(1)

        Text(schedule)
          .font(.footnote)
          .foregroundStyle(.secondary)
          .lineLimit(2)

        if showsRatings {
          ratings
        }

        if isAdded {
          status(String(localized: "In your timetable", bundle: .module), systemImage: "checkmark.circle.fill")
            .foregroundStyle(.tint)
        } else if !conflicts.isEmpty {
          status(
            String(localized: "Overlaps with \(conflicts.formatted(.list(type: .and)))", bundle: .module),
            systemImage: "exclamationmark.triangle.fill"
          )
          .foregroundStyle(.orange)
        }
      }
      .frame(maxWidth: .infinity, alignment: .leading)
    }
    .padding(.vertical, 2)
  }

  // Not a Label: list rows reduce a Label to its icon.
  private func status(_ text: String, systemImage: String) -> some View {
    HStack(alignment: .firstTextBaseline, spacing: 4) {
      Image(systemName: systemImage)
      Text(text)
        .lineLimit(2)
    }
    .font(.caption.weight(.medium))
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

/// A heart that saves a lecture to the wishlist, or takes it out.
struct WishlistButton: View {
  let isWishlisted: Bool
  let action: () -> Void

  var body: some View {
    Button(action: action) {
      Image(systemName: isWishlisted ? "heart.fill" : "heart")
        .font(.title3)
        .foregroundStyle(isWishlisted ? AnyShapeStyle(.pink) : AnyShapeStyle(.secondary))
        .contentTransition(.symbolEffect(.replace))
        .frame(minWidth: 36, minHeight: 36, alignment: .trailing)
        .contentShape(.rect)
    }
    .buttonStyle(.plain)
    .sensoryFeedback(.selection, trigger: isWishlisted)
    .accessibilityLabel(
      isWishlisted
        ? String(localized: "Remove from Wishlist", bundle: .module)
        : String(localized: "Add to Wishlist", bundle: .module)
    )
  }
}

/// A section's enrollment against its capacity, in orange once it is over.
private struct EnrollmentLabel: View {
  let lecture: Lecture

  var body: some View {
    HStack(spacing: 3) {
      Image(systemName: "person.2.fill")
      Text(verbatim: "\(lecture.enrolledCount)/\(lecture.capacity)")
        .monospacedDigit()
    }
    .font(.caption)
    .foregroundStyle(lecture.enrolledCount > lecture.capacity ? AnyShapeStyle(.orange) : AnyShapeStyle(.secondary))
    .fixedSize()
    .accessibilityElement(children: .ignore)
    .accessibilityLabel(String(localized: "\(lecture.enrolledCount) of \(lecture.capacity) enrolled", bundle: .module))
  }
}
