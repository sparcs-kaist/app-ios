//
//  LectureReviewsSection.swift
//  BuddyFeature
//
//  Created by Soongyu Kwon on 26/06/2025.
//

import SwiftUI
import BuddyDomain
import BuddyFeatureShared

/// The "Reviews" section of a lecture detail: summary letters, a write-review
/// action, and the review list (loading/loaded/error).
struct LectureReviewsSection: View {
  let gradeLetter: String
  let loadLetter: String
  let speechLetter: String
  let state: LectureDetailViewModel.ViewState
  @Binding var reviews: [LectureReview]
  let reviewDigest: ReviewDigestModel
  let reviewSummaries: ReviewSummaryModel
  /// Section subtitles by lecture ID, for the reviews' titles.
  var sectionSubtitles: [Int: String] = [:]
  let canWriteReview: Bool
  let onWriteReview: () -> Void

  var body: some View {
    VStack {
      HStack {
        Text("Reviews", bundle: .module)
          .font(.title3)
          .fontWeight(.bold)
        Spacer()
      }

      HStack {
        LectureSummaryRow(title: String(localized: "Grade", bundle: .module), description: gradeLetter)
        Spacer()
        LectureSummaryRow(title: String(localized: "Load", bundle: .module), description: loadLetter)
        Spacer()
        LectureSummaryRow(title: String(localized: "Speech", bundle: .module), description: speechLetter)
        Spacer()

        Button(action: onWriteReview, label: {
          Label(String(localized: "Write a Review", bundle: .module), systemImage: "square.and.pencil")
            .foregroundStyle(canWriteReview ? .primary : .secondary)
            .padding(8)
        })
        .font(.callout)
        .buttonStyle(.glassProminent)
        .tint(Color.secondarySystemBackground)
        .foregroundStyle(.primary)
        .disabled(!canWriteReview)
      }
      .padding(.vertical, 4)

      Spacer()
        .frame(height: 16)

      // Outside the lazy list, which would cancel the summary on scrolling it away.
      if state == .loaded, reviewDigest.canSummarise(reviews) {
        ReviewDigestCard(model: reviewDigest, reviews: reviews)
          .padding(.bottom, 16)
      }

      LazyVStack(spacing: 16) {
        switch state {
        case .loading:
          ForEach(LectureReview.mockList.prefix(2)) { review in
            LectureReviewCell(review: .constant(review))
              .redacted(reason: .placeholder)
              .disabled(true)
          }
        case .loaded:
          if reviews.isEmpty {
            // loaded but empty
            ContentUnavailableView(String(localized: "No Reviews", bundle: .module), systemImage: "text.book.closed", description: Text("There are no reviews for this lecture yet.", bundle: .module))
          } else {
            ForEach($reviews) { $review in
              LectureReviewCell(review: $review, subtitle: sectionSubtitles[review.lectureID])
            }
          }
        case .error(let message):
          ContentUnavailableView(String(localized: "Error", bundle: .module), systemImage: "wifi.exclamationmark", description: Text(message))
        }
      }
    }
    // Over the whole section rather than the summaries, so the reviews below
    // slide down as a summary grows instead of jumping.
    .animation(.spring, value: reviewDigest.phase)
    .animation(.spring, value: reviewSummaries.phases)
    .environment(reviewSummaries)
  }
}
