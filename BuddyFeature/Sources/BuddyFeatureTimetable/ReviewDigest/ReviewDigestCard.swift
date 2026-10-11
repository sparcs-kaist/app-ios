//
//  ReviewDigestCard.swift
//  BuddyFeature
//
//  Created by Soongyu Kwon on 11/10/2026.
//

import SwiftUI
import BuddyDomain
import BuddyFeatureShared

/// Above a lecture's reviews on devices that can summarise them: the summary as
/// it is written, or a button to write one when summaries aren't automatic.
/// The screen runs the summary; see `summarisesReviews(_:with:isLoaded:)`.
struct ReviewDigestCard: View {
  let model: ReviewDigestModel
  let reviews: [LectureReview]

  @AppStorage(ReviewSummarySettings.automaticKey)
  private var isAutomatic = ReviewSummarySettings.automaticDefault
  @Environment(\.colorScheme) private var colorScheme

  var body: some View {
    // One branch for waiting and reading, and one for writing and finished, so
    // the progress bar and the summary keep their identity between phases
    // instead of starting over.
    Group {
      if let progress = readingProgress {
        card { reading(completed: progress.completed, total: progress.total) }
      } else if let (digest, isFinished) = writtenDigest {
        card { digestContent(digest, isFinished: isFinished) }
      } else if case let .failed(message) = model.phase {
        card { failure(message) }
      } else {
        summariseButton
      }
    }
  }

  /// While waiting for the model, which an automatic summary does from the
  /// start, and while it reads.
  private var readingProgress: (completed: Int, total: Int)? {
    switch model.phase {
    case .idle: isAutomatic ? (0, 0) : nil
    case let .reading(completed, total): (completed, total)
    default: nil
    }
  }

  private var writtenDigest: (LectureReviewDigest, isFinished: Bool)? {
    switch model.phase {
    case let .writing(digest): (digest, false)
    case let .finished(digest): (digest, true)
    default: nil
    }
  }

  // MARK: - Phases

  private var summariseButton: some View {
    Button {
      model.requestSummary(of: reviews)
    } label: {
      Label(String(localized: "Summarise Reviews", bundle: .module), systemImage: "text.append")
        .frame(maxWidth: .infinity)
        .padding(.vertical, 6)
    }
    .buttonStyle(.glass)
    .transition(.opacity)
  }

  private func reading(completed: Int, total: Int) -> some View {
    VStack(alignment: .leading, spacing: 12) {
      header(title: String(localized: "Summarising…", bundle: .module))
      ReviewDigestProgressBar(completed: completed, total: total)
      Text("Reading reviews on this device…", bundle: .module)
        .font(.callout)
        .foregroundStyle(.secondary)
    }
  }

  private func digestContent(_ digest: LectureReviewDigest, isFinished: Bool) -> some View {
    VStack(alignment: .leading, spacing: 14) {
      header(title: isFinished
        ? String(localized: "Review Summary", bundle: .module)
        : String(localized: "Summarising…", bundle: .module))

      if let overview = digest.overview, !overview.isEmpty {
        Text(overview)
          .textSelection(.enabled)
      } else {
        // Holds the space until the first words arrive.
        Text(verbatim: "Lorem ipsum dolor sit amet, consectetur adipiscing elit. Nullam posuere pharetra.")
          .redacted(reason: .placeholder)
      }

      if !digest.liked.isEmpty {
        pointList(
          title: String(localized: "Liked", bundle: .module),
          systemImage: "hand.thumbsup.fill",
          tint: .green,
          points: digest.liked
        )
      }

      if !digest.disliked.isEmpty {
        pointList(
          title: String(localized: "Watch Out For", bundle: .module),
          systemImage: "exclamationmark.triangle.fill",
          tint: .orange,
          points: digest.disliked
        )
      }

      if let workload = digest.workload, !workload.isEmpty {
        aspect(title: String(localized: "Workload", bundle: .module), systemImage: "clock", text: workload)
      }

      if let grading = digest.grading, !grading.isEmpty {
        aspect(title: String(localized: "Grading", bundle: .module), systemImage: "graduationcap", text: grading)
      }

      if isFinished {
        Text("**Note:** Based on \(model.reviewCount) reviews. May contain errors, please double-check facts.", bundle: .module)
          .font(.footnote)
          .foregroundStyle(.secondary)
      }
    }
  }

  private func failure(_ message: String) -> some View {
    VStack(alignment: .leading, spacing: 12) {
      header(title: String(localized: "Review Summary", bundle: .module))
      Text(message)
        .foregroundStyle(.secondary)
      Button(String(localized: "Try Again", bundle: .module), systemImage: "arrow.clockwise") {
        model.requestSummary(of: reviews)
      }
      .buttonStyle(.glass)
    }
  }

  // MARK: - Pieces

  private func card(@ViewBuilder content: () -> some View) -> some View {
    content()
      .frame(maxWidth: .infinity, alignment: .leading)
      .padding()
      .background(colorScheme == .dark ? Color.secondarySystemGroupedBackground : .white)
      .clipShape(.rect(cornerRadius: 26))
      .shadow(color: .black.opacity(0.1), radius: 8)
      .transition(.asymmetric(
        insertion: .offset(y: -10).combined(with: .opacity),
        removal: .opacity
      ))
  }

  private func header(title: String) -> some View {
    Label(title, systemImage: "text.append")
      .font(.footnote.weight(.semibold))
      .foregroundStyle(.secondary)
      .textCase(.uppercase)
      .contentTransition(.numericText())
  }

  private func pointList(title: String, systemImage: String, tint: Color, points: [String]) -> some View {
    VStack(alignment: .leading, spacing: 6) {
      Label(title, systemImage: systemImage)
        .font(.subheadline.weight(.semibold))
        .foregroundStyle(tint)
      ForEach(Array(points.enumerated()), id: \.offset) { _, point in
        HStack(alignment: .firstTextBaseline, spacing: 8) {
          Text(verbatim: "•")
            .foregroundStyle(.tertiary)
          Text(point)
        }
        .font(.callout)
        .transition(.opacity)
      }
    }
    .accessibilityElement(children: .combine)
  }

  private func aspect(title: String, systemImage: String, text: String) -> some View {
    VStack(alignment: .leading, spacing: 4) {
      Label(title, systemImage: systemImage)
        .font(.subheadline.weight(.semibold))
        .foregroundStyle(.secondary)
      Text(text)
        .font(.callout)
    }
    .accessibilityElement(children: .combine)
  }
}

/// How far the model has read. Each batch of reviews takes several seconds with
/// nothing to report in between, so rather than standing still and jumping, the
/// bar eases most of the way towards the next step while it waits for it.
private struct ReviewDigestProgressBar: View {
  let completed: Int
  /// The batches to read, or 0 until the model says.
  let total: Int

  @State private var fraction = 0.0

  var body: some View {
    GeometryReader { proxy in
      Capsule()
        .fill(.quaternary)
        .overlay(alignment: .leading) {
          Capsule()
            .fill(.tint)
            .frame(width: proxy.size.width * fraction)
        }
    }
    .frame(height: 6)
    .onChange(of: Step(completed: completed, total: total), initial: true) { _, step in
      // Never backwards, such as when the number of batches becomes known.
      let target = max(fraction, step.target)
      withAnimation(.easeOut(duration: step.expectedDuration)) {
        fraction = target
      }
    }
    .accessibilityRepresentation {
      ProgressView(value: fraction)
    }
  }

  private struct Step: Equatable {
    var completed: Int
    var total: Int

    /// Most of the way to the end of this step. Writing the summary counts as
    /// a step after the last batch.
    var target: Double {
      guard total > 0 else { return 0.15 }
      return (Double(completed) + 0.9) / Double(total + 1)
    }

    /// Roughly how long a step takes on device, so the bar is still moving
    /// when the next one arrives.
    var expectedDuration: Double {
      total > 0 ? 15 : 4
    }
  }
}
