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
          .font(.callout)
          .fontWeight(.bold)
        Spacer()
        VStack(alignment: .trailing) {
          Text(course.code)
          Text(course.type.localized())
        }
        .font(.subheadline)
        .foregroundStyle(.secondary)
      }
      if course.summary != "" {
        Spacer()
          .frame(height: 16)
        Text(course.summary)
          .font(.footnote)
          .foregroundStyle(.secondary)
          .lineLimit(3)
      }
    }
    .padding()
    .background(Color.systemBackground, in: .rect(cornerRadius: 28.0))
  }
}

#Preview {
  ZStack {
    Color.secondarySystemBackground.ignoresSafeArea()
    CourseCell(course: Course.mock)
  }
}
