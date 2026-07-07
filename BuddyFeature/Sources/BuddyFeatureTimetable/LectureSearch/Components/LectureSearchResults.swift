//
//  LectureSearchResults.swift
//  BuddyFeature
//
//  Created by Soongyu Kwon on 20/09/2025.
//

import SwiftUI
import BuddyDomain

/// The grouped list of course sections and their lectures in the search sheet.
struct LectureSearchResults: View {
  let courses: [CourseLecture]
  @Binding var candidateLecture: Lecture?
  @Binding var detent: PresentationDetent
  let onAdd: (Lecture) -> Void

  var body: some View {
    ForEach(courses) { course in
      Section {
        courseHeader(course: course)
        ForEach(course.lectures) { lecture in
          NavigationLink(destination: {
            LectureDetailView(
              lecture: lecture,
              onAdd: {
                onAdd(lecture)
              },
              isOverlapping: false,
              lectureClass: lecture.classes.first
            )
            .onAppear {
              candidateLecture = lecture
              detent = .height(130)
            }
            .onDisappear {
              candidateLecture = nil
              detent = .large
            }
          }, label: {
            lectureRow(lecture: lecture)
          })
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
