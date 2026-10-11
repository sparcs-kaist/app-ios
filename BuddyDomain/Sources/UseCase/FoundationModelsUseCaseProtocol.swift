//
//  FoundationModelsUseCaseProtocol.swift
//  BuddyDomain
//
//  Created by Soongyu Kwon on 05/10/2025.
//

import Foundation

public protocol FoundationModelsUseCaseProtocol: Actor {
  func isAvailable() async -> Bool
  /// Streams a summary of plain `text` in the device's language, each update the
  /// summary written so far. `kind` decides what the summary keeps and how long
  /// it runs.
  ///
  /// The stream finishes by throwing a ``SummarisationError`` when the model is
  /// unavailable or cannot summarise the text. Cancelling the consuming task
  /// stops the generation.
  func streamSummary(of text: String, as kind: SummaryKind) -> AsyncThrowingStream<String, any Error>

  /// Turns a description of a timetable theme — a mood, a season, a palette —
  /// into a ``TimetableThemeBrief``, yielding a snapshot every time the model
  /// adds to it so the caller can preview the theme as it is written.
  ///
  /// The stream finishes by throwing a ``TimetableThemeGenerationError`` when
  /// the model is unavailable or refuses the description. Cancelling the
  /// consuming task stops the generation.
  ///
  /// - Parameter variation: Seeds the model's sampling, so asking again for
  ///   the same description gives a different answer rather than the same one.
  ///   The same seed asks for the same answer back.
  func streamThemeBrief(
    describing description: String,
    variation: UInt64
  ) -> AsyncThrowingStream<TimetableThemeBrief, any Error>

  /// Reads a lecture's reviews and streams a ``LectureReviewDigest`` of them,
  /// written in the device's language whatever language the reviews are in.
  ///
  /// The stream finishes by throwing a ``LectureReviewDigestError`` when the
  /// model is unavailable or cannot read the reviews. Cancelling the consuming
  /// task stops the generation.
  func streamReviewDigest(
    of reviews: [LectureReview]
  ) -> AsyncThrowingStream<LectureReviewDigestProgress, any Error>

  /// Reads a description of a weekly activity, such as "Study group every
  /// Tuesday 7–9pm at the library", into the fields of the activity form.
  ///
  /// - Parameter today: Resolves "today" and "tomorrow" in the description.
  /// - Throws: An ``ActivityParsingError``.
  func parseActivity(_ description: String, today: DayType) async throws -> ParsedActivity
}
