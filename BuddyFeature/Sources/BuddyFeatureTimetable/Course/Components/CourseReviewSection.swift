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
  let reviewDigest: ReviewDigestModel
  let reviewSummaries: ReviewSummaryModel
  /// Section subtitles by lecture ID, for the reviews' titles.
  var sectionSubtitles: [Int: String] = [:]

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

      // Outside the lazy list, which would cancel the summary on scrolling it away.
      if isLoaded, reviewDigest.canSummarise(reviews) {
        ReviewDigestCard(model: reviewDigest, reviews: reviews)
          .padding(.bottom, 16)
      }

      LazyVStack(spacing: 16) {
        if isLoaded {
          if reviews.isEmpty {
            Text("No reviews yet.", bundle: .module)
              .font(.callout)
              .foregroundStyle(.secondary)
              .frame(maxWidth: .infinity)
              .padding(.vertical, 24)
          }
          ForEach($reviews) { $review in
            LectureReviewCell(review: $review, subtitle: sectionSubtitles[review.lectureID])
          }
        } else {
          ForEach(LectureReview.mockList.prefix(3)) { review in
            LectureReviewCell(review: .constant(review))
              .redacted(reason: .placeholder)
              .disabled(true)
          }
        }
      }
    }
    // Over the whole section rather than the summaries, so the reviews below
    // slide down as a summary grows instead of jumping.
    .animation(.spring, value: reviewDigest.phase)
    .animation(.spring, value: reviewSummaries.phases)
    .environment(reviewSummaries)
  }

  private func summaryRow(title: String, description: String) -> some View {
    LectureSummaryRow(title: title, description: description)
      .frame(width: 75)
  }
}
