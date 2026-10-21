//
//  CourseSummarySection.swift
//  BuddyFeature
//
//  Created by 하정우 on 9/30/25.
//

import SwiftUI
import BuddyFeatureShared

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
  /// Hides the duration and credit numbers, which only arrive with the full course.
  var isLoadingDetails: Bool = false
  var isTaken: Bool = false

  var body: some View {
    VStack(spacing: 20) {
      HStack {
        summaryRow(title: String(localized: "Hours", bundle: .module), description: String(classDuration))
        summaryRow(title: String(localized: "Lab", bundle: .module), description: String(expDuration))
        if credit == 0 {
          summaryRow(title: String(localized: "AU", bundle: .module), description: String(creditAU))
        } else {
          summaryRow(title: String(localized: "Credit", bundle: .module), description: String(credit))
        }
      }
      .redacted(reason: isLoadingDetails ? .placeholder : [])

      VStack(alignment: .leading) {
        HStack {
          Text("Information", bundle: .module)
            .font(.title3)
            .fontWeight(.bold)
          Spacer()
          if isTaken {
            TakenBadge()
          }
        }

        LectureDetailRow(title: String(localized: "Code", bundle: .module), description: code)
        LectureDetailRow(title: String(localized: "Type", bundle: .module), description: typeName)
        LectureDetailRow(title: String(localized: "Department", bundle: .module), description: departmentName)

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
