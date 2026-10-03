//
//  LectureInformationSection.swift
//  BuddyFeature
//
//  Created by Soongyu Kwon on 26/06/2025.
//

import SwiftUI
import BuddyDomain

/// The "Information" section of a lecture detail: code, type, department, etc.
struct LectureInformationSection: View {
  let lecture: Lecture
  let lectureClass: LectureClass?

  @Environment(\.openCourse) private var openCourse

  var body: some View {
    VStack {
      HStack {
        Text("Information", bundle: .module)
          .font(.title3)
          .fontWeight(.bold)
        Spacer()
        // Every semester and professor of this course, beyond this one lecture.
        if let openCourse {
          Button {
            openCourse(lecture.courseID, lecture.name)
          } label: {
            viewCourseLabel
          }
        } else {
          NavigationLink {
            CourseView(courseID: lecture.courseID, name: lecture.name)
          } label: {
            viewCourseLabel
          }
        }
      }

      LectureDetailRow(title: String(localized: "Code", bundle: .module), description: lecture.code)
      LectureDetailRow(
        title: String(localized: "Type", bundle: .module),
        description: lecture.type.displayName.localized()
      )
      LectureDetailRow(title: String(localized: "Department", bundle: .module), description: lecture.department.name)
      LectureDetailRow(
        title: String(localized: "Professor", bundle: .module),
        description: lecture.professors.isEmpty ? String(localized: "Unknown", bundle: .module) : lecture.professors.map { $0.name }.joined(separator: "\n")
      )
      if let lectureClass {
        LectureDetailRow(
          title: String(localized: "Classroom", bundle: .module),
          description: "\(lectureClass.buildingCode) \(lectureClass.roomName)"
        )
      }
      LectureDetailRow(title: String(localized: "Capacity", bundle: .module), description: String(lecture.capacity))
      LectureDetailRow(
        title: String(localized: "Exams", bundle: .module),
        description: lecture.exams.isEmpty ? String(localized: "Unknown", bundle: .module) : lecture.exams
          .map { $0.description }
          .joined(separator: "\n")
      )
    }
  }

  private var viewCourseLabel: some View {
    HStack(spacing: 4) {
      Text("View Course", bundle: .module)
      Image(systemName: "chevron.right")
        .font(.footnote.weight(.semibold))
    }
    .font(.subheadline)
  }
}
