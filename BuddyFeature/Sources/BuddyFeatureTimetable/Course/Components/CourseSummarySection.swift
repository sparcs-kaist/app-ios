//
//  CourseSummarySection.swift
//  BuddyFeature
//
//  Created by 하정우 on 9/30/25.
//

import SwiftUI

/// A course's duration/credit summary and its information rows.
struct CourseSummarySection: View {
  let classDuration: Int
  let expDuration: Int
  let credit: Int
  let creditAU: Int
  let code: String
  let typeName: String
  let departmentName: String
  let summary: String

  var body: some View {
    VStack(spacing: 20) {
      HStack {
        summaryRow(title: "Hours", description: String(classDuration))
        summaryRow(title: "Lab", description: String(expDuration))
        if credit == 0 {
          summaryRow(title: "AU", description: String(creditAU))
        } else {
          summaryRow(title: "Credit", description: String(credit))
        }
      }

      VStack(alignment: .leading) {
        HStack {
          Text("Information", bundle: .module)
            .font(.title3)
            .fontWeight(.bold)
          Spacer()
        }

        LectureDetailRow(title: "Code", description: code)
        LectureDetailRow(title: "Type", description: typeName)
        LectureDetailRow(title: "Department", description: departmentName)

        if summary != "" {
          Text("Summary", bundle: .module)
            .foregroundStyle(.secondary)
            .font(.callout)
            .padding(.vertical, 4)

          Text(summary)
            .font(.footnote)
            .multilineTextAlignment(.leading)
        }
      }
    }
    .padding(.bottom)
  }

  private func summaryRow(title: String, description: String) -> some View {
    LectureSummaryRow(title: title, description: description)
      .frame(width: 75)
  }
}
