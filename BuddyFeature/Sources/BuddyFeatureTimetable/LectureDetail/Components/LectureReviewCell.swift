//
//  LectureReviewCell.swift
//  soap
//
//  Created by Soongyu Kwon on 02/10/2025.
//

import Foundation
import SwiftUI
import Translation
import Factory
import BuddyDomain
import Haptica
import BuddyFeatureShared
import os

private let logger = Logger(subsystem: "org.sparcs.soap", category: "LectureReviewCell")

struct LectureReviewCell: View {
  @Binding var review: LectureReview

  @ObservationIgnored @Injected(
    \.v2ReviewUseCase
  ) private var reviewUseCase: ReviewUseCaseProtocol?

  /// The screen's summaries, so a summary outlives this cell scrolling away.
  /// Absent for placeholder cells, which then offer no summary.
  @Environment(ReviewSummaryModel.self) private var summaries: ReviewSummaryModel?
  @Environment(\.colorScheme) var colorScheme
  @Environment(\.openURL) private var openURL
  @State private var showTranslateSheet: Bool = false
  @State private var isLikeButtonRunning: Bool = false

  private var summaryPhase: ReviewSummaryModel.Phase? {
    summaries?.phase(for: review)
  }

  var body: some View {
    VStack(alignment: .leading, spacing: 8) {
      HStack {
        Text(review.professors.first?.name ?? String(localized: "Unknown", bundle: .module))
          .font(.headline)

        Text(String(review.year).suffix(2) + review.semester.shortCode)
          .foregroundStyle(.secondary)
          .fontDesign(.rounded)
          .fontWeight(.semibold)

        Spacer()

        Menu {
          Button(String(localized: "Translate", bundle: .module), systemImage: "translate") { showTranslateSheet = true }
          if let summaries, summaries.canSummarise(review) {
            Button(String(localized: "Summarise", bundle: .module), systemImage: "text.append") {
              Haptic.start.generate()
              summaries.summarise(review)
            }
            .disabled(summaryPhase != nil)
          }
//          Divider()
//          Button(String(localized: "Report", bundle: .module), systemImage: "exclamationmark.triangle.fill") { report() }
        } label: {
          Label(String(localized: "More", bundle: .module), systemImage: "ellipsis")
            .padding(8)
            .contentShape(.rect)
        }
        .labelStyle(.iconOnly)
      }

      if let summaryPhase {
        summary(summaryPhase)
          .padding(.bottom)
          .transition(.asymmetric(
            insertion: .offset(y: -10).combined(with: .opacity),
            removal: .opacity
          ))
      }

      Text(review.content)
        .truncationMode(.head)
        .textSelection(.enabled)

      HStack(alignment: .bottom) {
        reviewRatingLetter(title: String(localized: "Grade", bundle: .module), rating: review.grade)
        reviewRatingLetter(title: String(localized: "Load", bundle: .module), rating: review.load)
        reviewRatingLetter(title: String(localized: "Speech", bundle: .module), rating: review.speech)

        Spacer()

        Button(action: {
          guard !isLikeButtonRunning else { return }
          
          isLikeButtonRunning = true
          Task {
            await toggleLike()
            isLikeButtonRunning = false
          }
        }, label: {
          HStack {
            Text("\(review.like)")
            Image(systemName: review.likedByUser ? "arrowshape.up.fill" : "arrowshape.up")
          }
        })
        .tint(review.likedByUser ? Color.upvote : .primary)
        .contentTransition(.numericText(value: Double(review.like)))
        .buttonStyle(.glass)
        .animation(.spring, value: review.likedByUser)
      }
    }
    .padding()
    .background(colorScheme == .dark ? Color.secondarySystemGroupedBackground : .white)
    .clipShape(.rect(cornerRadius: 26))
    .shadow(color: .black.opacity(0.1), radius: 8)
    .translationPresentation(isPresented: $showTranslateSheet, text: review.content)
    .sensoryFeedback(trigger: summaryPhase) { _, phase in
      switch phase {
      case .finished: .success
      case .failed: .error
      default: nil
      }
    }
  }

  @ViewBuilder
  private func summary(_ phase: ReviewSummaryModel.Phase) -> some View {
    switch phase {
    case let .summarising(text):
      SummarisationView(text: text, isSummarising: true)
    case let .finished(text):
      SummarisationView(text: text)
    case let .failed(message):
      VStack(alignment: .leading, spacing: 8) {
        Label(message, systemImage: "exclamationmark.triangle")
          .font(.footnote)
          .foregroundStyle(.secondary)
        Button(String(localized: "Try Again", bundle: .module), systemImage: "arrow.clockwise") {
          summaries?.summarise(review)
        }
        .font(.footnote)
        .buttonStyle(.glass)
      }
    }
  }

  private func reviewRatingLetter(title: String, rating: String) -> some View {
    HStack(spacing: 4) {
      Text(title)
        .foregroundStyle(.tertiary)
        .fontWeight(.medium)
        .textCase(.uppercase)

      Text(rating)
        .foregroundStyle(.secondary)
        .fontDesign(.rounded)
        .fontWeight(.semibold)
    }
    .font(.footnote)
  }

  // MARK: - Helpers
//  private func report() {
//    if let urlString = ReportMailComposer.compose(
//      title: review.title.localized(),
//      code: review.lecture.code,
//      year: review.lecture.year,
//      semester: review.lecture.semester,
//      professorName: review.lecture.professors.first?.name.localized() ?? String(localized: "Unknown", bundle: .module),
//      content: review.content
//    ), let url = URL(string: urlString),
//       UIApplication.shared.canOpenURL(url) {
//      openURL(url)
//    }
//  }

  private func toggleLike() async {
    guard let reviewUseCase else { return }

    let prevLiked = review.likedByUser
    let prevLikeCount = review.like

    do {
      if prevLiked {
        Haptic.decrease.generate()
        review.likedByUser = false
        review.like -= 1
        try await reviewUseCase.unlikeReview(reviewID: review.id)
      } else {
        Haptic.increase.generate()
        review.likedByUser = true
        review.like += 1
        try await reviewUseCase.likeReview(reviewID: review.id)
      }
    } catch {
      logger.error("Failed to toggle like: \(error.localizedDescription, privacy: .public)")
      review.likedByUser = prevLiked
      review.like = prevLikeCount
    }
  }
}
//
//#Preview {
//  LectureReviewCell(review: .constant(LectureReview.mock))
//}

