//
//  CourseCell.swift
//  soap
//
//  Created by 하정우 on 9/29/25.
//

import SwiftUI
import BuddyDomain

struct CourseCell: View {
  let course: CourseSummary

  var body: some View {
    VStack(alignment: .leading, spacing: 16) {
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
        .lineLimit(1)
        .font(.footnote)
        .foregroundStyle(.secondary)
      }

      if !course.summary.isEmpty {
        Text(course.summary)
          .lineLimit(3)
          .multilineTextAlignment(.leading)
          .font(.footnote)
          .foregroundStyle(.secondary)
      }
    }
    .padding()
  }
}

//#Preview {
//  ZStack {
//    Color.secondarySystemBackground.ignoresSafeArea()
//    SearchSection(title: "Courses", searchScope: .constant(.all), targetScope: .courses) {
//      SearchContent<Course, CourseCell>(results: Course.mockList) {
//        CourseCell(course: $0)
//      }
//    }
//  }
//}
