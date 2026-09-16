//
//  FoundationModelsUseCaseProtocol.swift
//  BuddyDomain
//
//  Created by Soongyu Kwon on 05/10/2025.
//

import Foundation

public protocol FoundationModelsUseCaseProtocol: Actor {
  func isAvailable() async -> Bool
  func summarise(_ text: String, maxWords: Int, tone: String) async -> String

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
}
