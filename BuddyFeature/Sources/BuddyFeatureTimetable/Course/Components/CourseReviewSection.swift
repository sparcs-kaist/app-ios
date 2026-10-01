//
//  CourseReviewSection.swift
//  BuddyFeature
//
//  Created by 하정우 on 9/30/25.
//

import SwiftUI
import BuddyDomain

/// A course's aggregate review letters and the list of reviews.
struct CourseReviewSection: View {
  let gradeLetter: String
  let loadLetter: String
  let speechLetter: String
  /// The professor the reviews are narrowed to, if any.
  var professorName: String? = nil
  let isLoaded: Bool
  @Binding var reviews: [LectureReview]

  var body: some View {
    VStack {
      HStack {
        VStack(alignment: .leading, spacing: 2) {
          Text("Reviews", bundle: .module)
            .font(.title3)
            .fontWeight(.bold)
          if let professorName {
            Text(professorName)
              .font(.footnote)
              .foregroundStyle(.secondary)
              .lineLimit(1)
          }
        }
        Spacer()

        summaryRow(title: "Grade", description: gradeLetter)
        summaryRow(title: "Load", description: loadLetter)
        summaryRow(title: "Speech", description: speechLetter)
      }

      Spacer()
        .frame(height: 16)

      LazyVStack(spacing: 16) {
        if isLoaded {
          ForEach($reviews) { $review in
            LectureReviewCell(review: $review)
          }
        } else {
          ForEach(LectureReview.mockList.prefix(3)) { review in
            LectureReviewCell(review: .constant(review))
              .redacted(reason: .placeholder)
          }
        }
      }
    }
  }

  private func summaryRow(title: String, description: String) -> some View {
    LectureSummaryRow(title: title, description: description)
      .frame(width: 75)
  }
}
