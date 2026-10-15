//
//  SummarisesReviews.swift
//  BuddyFeature
//
//  Created by Soongyu Kwon on 11/10/2026.
//

import SwiftUI
import BuddyDomain

extension View {
  /// Writes `model`'s summary of `reviews` while this screen is on screen:
  /// straight away when summaries are automatic, otherwise once one is asked
  /// for. Leaving the screen stops the model, and coming back starts it again.
  ///
  /// Applied to the screen rather than to the summary card, because a lazy stack
  /// creates the card only once it is scrolled to, and drops it again once it
  /// is scrolled away.
  func summarisesReviews(_ reviews: [LectureReview], with model: ReviewDigestModel, isLoaded: Bool) -> some View {
    modifier(SummarisesReviews(reviews: reviews, model: model, isLoaded: isLoaded))
  }
}

private struct SummarisesReviews: ViewModifier {
  let reviews: [LectureReview]
  let model: ReviewDigestModel
  let isLoaded: Bool

  @AppStorage(ReviewSummarySettings.automaticKey)
  private var isAutomatic = ReviewSummarySettings.automaticDefault

  func body(content: Content) -> some View {
    content
      .task(id: Request(
        reviewIDs: isLoaded ? reviews.map(\.id) : [],
        attempt: model.attempt,
        isAutomatic: isAutomatic,
        isAvailable: model.isAvailable
      )) {
        guard isLoaded else { return }
        await model.summariseIfNeeded(reviews, automatically: isAutomatic)
      }
  }

  private struct Request: Equatable {
    var reviewIDs: [Int]
    var attempt: Int
    var isAutomatic: Bool
    var isAvailable: Bool
  }
}
