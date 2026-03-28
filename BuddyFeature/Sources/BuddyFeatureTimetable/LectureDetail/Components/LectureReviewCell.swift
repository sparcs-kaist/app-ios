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
import FoundationModels
import BuddyFeatureShared

struct LectureReviewCell: View {
  @Binding var review: LectureReview

  @ObservationIgnored @Injected(
    \.v2ReviewUseCase
  ) private var reviewUseCase: ReviewUseCaseProtocol?
  @Injected(
    \.foundationModelsUseCase
  ) private var foundationModelsUseCase: FoundationModelsUseCaseProtocol?

  @Environment(\.colorScheme) var colorScheme
  @Environment(\.openURL) private var openURL
  @State private var showTranslateSheet: Bool = false
  @State private var summarisedContent: String? = nil
  @State private var isLikeButtonRunning: Bool = false

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
          if SystemLanguageModel.default.isAvailable {
            Button(String(localized: "Summarise", bundle: .module), systemImage: "text.append") {
              guard let foundationModelsUseCase else { return }
              
              summarisedContent = ""
              Task {
                Haptic.start.generate()
                summarisedContent = await foundationModelsUseCase
                  .summarise(review.content, maxWords: 50, tone: "concise")
                Haptic.success.generate()
              }
            }
            .disabled(summarisedContent != nil)
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

      if let summarisedContent {
        SummarisationView(text: summarisedContent)
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
            Text(String(localized: "\(review.like)", bundle: .module))
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
    .animation(.spring(), value: summarisedContent)
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
      review.likedByUser = prevLiked
      review.like = prevLikeCount
    }
  }
}
//
//#Preview {
//  LectureReviewCell(review: .constant(LectureReview.mock))
//}

