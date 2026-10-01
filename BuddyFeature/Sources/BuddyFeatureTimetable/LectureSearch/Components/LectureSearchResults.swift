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

/// The grouped list of course sections and their lectures in the search sheet.
struct LectureSearchResults: View {
  let courses: [CourseLecture]

  var body: some View {
    ForEach(courses) { course in
      Section {
        // The course page shows every semester it was offered and who taught it.
        NavigationLink(value: LectureSearchRoute.course(id: course.id, name: course.name)) {
          courseHeader(course: course)
        }
        ForEach(course.lectures) { lecture in
          NavigationLink(value: LectureSearchRoute.lecture(lecture)) {
            lectureRow(lecture: lecture)
          }
        }
      }
    }
  }

  private func courseHeader(course: CourseLecture) -> some View {
    HStack {
      Text(course.name)
        .lineLimit(2)
        .multilineTextAlignment(.leading)
        .font(.callout)
        .fontWeight(.semibold)

      Spacer()

      VStack(alignment: .trailing) {
        Text(course.code)
        Text(course.type.displayName.localized())
      }
      .foregroundStyle(.secondary)
      .font(.footnote)
    }
  }

  private func lectureRow(lecture: Lecture) -> some View {
    HStack {
      Text(lecture.section)
        .fontDesign(.rounded)
        .foregroundStyle(.secondary)

      Text(lecture.professors.first?.name ?? String(localized: "Unknown", bundle: .module))

      Spacer()
    }
    .font(.callout)
  }
}
