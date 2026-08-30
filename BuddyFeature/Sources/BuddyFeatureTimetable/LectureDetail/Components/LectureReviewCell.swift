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
import FoundationModels
import BuddyFeatureShared
import os

private let logger = Logger(subsystem: "org.sparcs.soap", category: "LectureReviewCell")

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
                BuddyHaptic.start.generate()
                summarisedContent = await foundationModelsUseCase
                  .summarise(review.content, maxWords: 50, tone: "concise")
                BuddyHaptic.success.generate()
              }
            }
            .disabled(summarisedContent != nil)
          }
//          Divider()
//          Button(String(localized: "Report", bundle: .module), systemImage: "exclamationmark.triangle.fill") { report() }
        } label: {
          Label(String(localized: "More", bundle: .module), systemImage: "ellipsis")
            .labelStyle(.iconOnly)
            .padding(8)
            .contentShape(.rect)
        }
        #if os(macOS)
        // macOS defaults to the bordered button menu style, which paints an opaque
        // capsule inside the cell's own background and squashes the label's padding.
        // Rendering it as a plain button leaves just the ellipsis, as on iOS.
        .menuStyle(.button)
        .buttonStyle(.plain)
        // A plain button menu still draws the style's own chevron next to the label.
        .menuIndicator(.hidden)
        // macOS hides icons of menu items built from a Label unless asked otherwise.
        // The label's own `.iconOnly` stays applied to the ellipsis itself, so the
        // items keep their titles instead of collapsing to bare icons.
        .labelStyle(.titleAndIcon)
        #endif
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
            Text("\(review.like)")
            Image(systemName: review.likedByUser ? "arrowshape.up.fill" : "arrowshape.up")
          }
          #if os(macOS)
          // AppKit tints a button's background rather than its label, so `.tint`
          // would paint the whole pill instead of the arrow and the count.
					.padding(.horizontal, 4)
          .foregroundStyle(review.likedByUser ? Color.upvote : .primary)
          .macOSPlainHitArea()
          #endif
        })
        .contentTransition(.numericText(value: Double(review.like)))
        .animation(.spring, value: review.likedByUser)
        #if os(macOS)
        // `.buttonStyle(.glass)` keeps AppKit's push-button metrics, which squashes the
        // label and nests an opaque capsule inside the cell's own background. Matching
        // PostVoteButton — a plain button with an explicit glass effect — restores the
        // iOS appearance.
        .macOSPlainButtons()
        .padding(8)
        .glassEffect(.regular.interactive())
        #else
        .tint(review.likedByUser ? Color.upvote : .primary)
        .buttonStyle(.glass)
        #endif
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
        BuddyHaptic.decrease.generate()
        review.likedByUser = false
        review.like -= 1
        try await reviewUseCase.unlikeReview(reviewID: review.id)
      } else {
        BuddyHaptic.increase.generate()
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

