//
//  CourseCell.swift
//  soap
//
//  Created by 하정우 on 9/29/25.
//

import SwiftUI

struct CourseCell: View {
  let course: Course
  
  var body: some View {
    VStack(alignment: .leading) {
      HStack(alignment: .top) {
        Text(course.title.localized())
          .lineLimit(2)
          .multilineTextAlignment(.leading)
          .font(.callout)
          .fontWeight(.bold)
          .frame(width: 150, alignment: .leading)
        Spacer()
        VStack(alignment: .trailing) {
          Text(course.code)
          Text(course.type.localized())
        }
        .lineLimit(1)
        .font(.subheadline)
        .foregroundStyle(.secondary)
        .frame(width: 150, alignment: .trailing)
      }
      if course.summary != "" {
        Spacer()
          .frame(height: 16)
        Text(course.summary)
          .lineLimit(3)
          .multilineTextAlignment(.leading)
          .font(.footnote)
          .foregroundStyle(.secondary)
      }
    }
    .padding()
    .background(Color.systemBackground, in: .rect(cornerRadius: 28.0))
  }
}

#Preview {
  ZStack {
    Color.secondarySystemBackground.ignoresSafeArea()
    SearchSection(title: "Courses", searchScope: .constant(.all), targetScope: .courses) {
      SearchContent<Course, CourseCell>(results: Course.mockList) {
        CourseCell(course: $0)
      }
    }
  }
}
