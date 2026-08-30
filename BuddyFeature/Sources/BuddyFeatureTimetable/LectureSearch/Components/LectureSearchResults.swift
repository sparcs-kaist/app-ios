//
//  LectureSearchResults.swift
//  BuddyFeature
//
//  Created by Soongyu Kwon on 20/09/2025.
//

import SwiftUI
import BuddyDomain

/// The grouped list of course sections and their lectures in lecture search.
struct LectureSearchResults: View {
  let courses: [CourseLecture]
  let onSelect: (Lecture) -> Void
  let onAdd: (Lecture) -> Void
  let onHover: (Lecture, Bool) -> Void

  var body: some View {
    ForEach(courses) { course in
      Section {
        courseHeader(course: course)
        ForEach(course.lectures) { lecture in
          #if os(macOS)
          HStack(spacing: 12) {
            Button {
              onSelect(lecture)
            } label: {
							HStack {
								lectureRow(lecture: lecture)
								Image(systemName: "chevron.right")
							}
							.frame(maxWidth: .infinity, alignment: .leading)
							.contentShape(.rect)
            }
            .buttonStyle(.plain)

            Button(String(localized: "Add", bundle: .module), systemImage: "plus") {
              onAdd(lecture)
            }
          }
          .contentShape(.rect)
          .onHover { isHovering in
            onHover(lecture, isHovering)
          }
          #else
          Button {
            onSelect(lecture)
          } label: {
            lectureRow(lecture: lecture)
              .frame(maxWidth: .infinity, alignment: .leading)
              .contentShape(.rect)
          }
          .buttonStyle(.plain)
          #endif
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

      #if !os(macOS)
      Image(systemName: "chevron.right")
        .font(.caption.weight(.semibold))
        .foregroundStyle(.tertiary)
      #endif
    }
    .font(.callout)
  }
}
