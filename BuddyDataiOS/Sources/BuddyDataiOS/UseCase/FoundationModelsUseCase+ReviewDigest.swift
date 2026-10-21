//
//  FoundationModelsUseCase+ReviewDigest.swift
//  BuddyDataiOS
//
//  Created by Soongyu Kwon on 11/10/2026.
//

import Foundation
import FoundationModels
import BuddyDomain
import BuddyDataCore

/// The shape the model fills in, in the order it streams: the overview first,
/// as it is what someone reads first.
@Generable(description: "What students say about a university lecture across its reviews")
private struct GeneratedDigest {
  @Guide(description: "One or two sentences on the overall impression students have of the lecture.")
  var overview: String

  @Guide(description: "What students liked, each a short phrase of a few words, most mentioned first.", .maximumCount(4))
  var liked: [String]

  @Guide(description: "What students disliked or warned about, each a short phrase of a few words, most mentioned first. Empty if nothing.", .maximumCount(4))
  var disliked: [String]

  @Guide(description: "One short sentence on the workload: assignments, exams and the time it takes.")
  var workload: String

  @Guide(description: "One short sentence on how generously the lecture is graded.")
  var grading: String
}

extension FoundationModelsUseCase {
  /// How the reviews' ratings read, shared by both sets of instructions.
  /// Model-facing, so deliberately not localised.
  private static let ratingsExplanation = """
    Each review is on its own line and starts with its ratings in brackets. \
    Grade is how generously the lecture is graded, Load is how light its \
    workload is, and Speech is how good the lecturing is. Higher ratings are \
    better in all three.
    """

  /// For the digest itself, written from reviews or from notes on them.
  private static func digestInstructions(language: String) -> String {
    """
    You summarise what university students say about a lecture in their \
    course reviews, or in notes taken from those reviews.

    \(ratingsExplanation)

    Report only what the reviews say, giving what most reviewers agree on \
    rather than what a single reviewer says. Never name a reviewer, and never \
    invent details such as exam counts or percentages that no review gives.

    Write in \(language), whatever language the reviews are in. Keep every \
    phrase short.
    """
  }

  /// For reading a batch of reviews when they do not all fit at once. In the
  /// digest's language, as notes in another language pull the digest into it.
  private static func notesInstructions(language: String) -> String {
    """
    You take notes on university students' course reviews of a lecture, for \
    someone who will summarise them later.

    \(ratingsExplanation)

    Write at most six short bullet points in \(language) covering the overall \
    impression, what students liked, what they disliked, the workload and the \
    grading. Say when several reviews agree. Leave out anything personal or \
    offensive.
    """
  }

  /// Tokens kept back from the context for the instructions, the response
  /// schema and the response.
  private static let reservedTokens = 1_500

  public func streamReviewDigest(
    of reviews: [LectureReview]
  ) -> AsyncThrowingStream<LectureReviewDigestProgress, any Error> {
    let lines = LectureReviewBatching.lines(for: reviews)

    return AsyncThrowingStream { continuation in
      // As in `streamThemeBrief`, every session lives and dies inside this task.
      let task = Task {
        let model = SystemLanguageModel.default
        guard case .available = model.availability else {
          continuation.finish(throwing: LectureReviewDigestError.unavailable)
          return
        }
        guard !lines.isEmpty else {
          continuation.finish(throwing: LectureReviewDigestError.noReviews)
          return
        }

        let batches = await LectureReviewBatching.batches(
          of: lines,
          budget: max(model.contextSize - Self.reservedTokens, 1_000),
          cost: Self.tokenCount
        )
        continuation.yield(.started(reviewCount: batches.reduce(0) { $0 + $1.count }))
        let language = Self.deviceLanguage(model: model)
        let instructions = Self.digestInstructions(language: language)

        do {
          // Reviews that fit at once are summarised straight away. Blunt
          // reviews can trip the guardrails, so when they do the reviews are
          // read into notes first, which permits rewording what it reads.
          if batches.count == 1 {
            do {
              try await Self.streamDigest(
                from: batches[0].joined(separator: "\n"),
                language: language,
                instructions: instructions,
                into: continuation
              )
              continuation.finish()
              return
            } catch where Self.isGuardrailViolation(error) { }
          }

          var notes: [String] = []
          for (index, batch) in batches.enumerated() {
            continuation.yield(.reading(completed: index, total: batches.count))
            notes.append(try await Self.notes(on: batch, language: language))
          }
          continuation.yield(.reading(completed: batches.count, total: batches.count))

          try await Self.streamDigest(
            from: notes.joined(separator: "\n"),
            language: language,
            instructions: instructions,
            into: continuation
          )
          continuation.finish()
        } catch is CancellationError {
          continuation.finish()
        } catch {
          continuation.finish(throwing: Self.digestError(for: error))
        }
      }
      continuation.onTermination = { _ in task.cancel() }
    }
  }

  private static func streamDigest(
    from reviews: String,
    language: String,
    instructions: String,
    into continuation: AsyncThrowingStream<LectureReviewDigestProgress, any Error>.Continuation
  ) async throws {
    let session = LanguageModelSession(model: .default, instructions: instructions)
    let stream = session.streamResponse(
      // Repeated from the instructions: reviews or notes in another language
      // otherwise pull the digest into theirs.
      to: "Summarise these reviews in \(language):\n\(reviews)",
      generating: GeneratedDigest.self,
      // The same reviews should read the same way each time they're summarised.
      options: GenerationOptions(samplingMode: .greedy)
    )
    for try await snapshot in stream {
      continuation.yield(.writing(LectureReviewDigest(snapshot.content)))
    }
  }

  private static func notes(on batch: [String], language: String) async throws -> String {
    let session = LanguageModelSession(
      model: SystemLanguageModel(guardrails: .permissiveContentTransformations),
      instructions: notesInstructions(language: language)
    )
    let response = try await session.respond(
      to: "Take notes on these reviews:\n\(batch.joined(separator: "\n"))",
      options: GenerationOptions(samplingMode: .greedy)
    )
    return response.content
  }

  /// Counts exactly where the system can, and guesses high where it cannot.
  @Sendable private static func tokenCount(_ text: String) async -> Int {
    if #available(iOS 26.4, *),
       let count = try? await SystemLanguageModel.default.tokenCount(for: text) {
      return count
    }
    return LectureReviewBatching.estimatedTokens(text)
  }

  /// The device's language, named in English for the model, or English when
  /// the model cannot write the device's language. Debug builds can force a
  /// language from Debug Settings, whether or not the model claims to write it.
  static func deviceLanguage(model: SystemLanguageModel) -> String {
    #if DEBUG
    if let code = ModelLanguageSettings.forcedLanguageCode {
      return Locale(identifier: "en").localizedString(forLanguageCode: code) ?? "English"
    }
    #endif
    let device = Locale(identifier: Locale.preferredLanguages.first ?? "en")
    guard model.supportsLocale(device), let code = device.language.languageCode?.identifier else {
      return "English"
    }
    return Locale(identifier: "en").localizedString(forLanguageCode: code) ?? "English"
  }

  /// As in `generationError(for:)`, iOS 27 and iOS 26 throw different types.
  static func isGuardrailViolation(_ error: any Error) -> Bool {
    if #available(iOS 27, *), let error = error as? LanguageModelError {
      if case .guardrailViolation = error { return true }
      if case .refusal = error { return true }
      return false
    }
    if let error = error as? LanguageModelSession.GenerationError {
      if case .guardrailViolation = error { return true }
      if case .refusal = error { return true }
    }
    return false
  }

  private static func digestError(for error: any Error) -> LectureReviewDigestError {
    isGuardrailViolation(error) ? .unsafeContent : .failed
  }
}

private extension LectureReviewDigest {
  /// Adapts a snapshot of the generated type, which has every property
  /// optional while the model is still writing.
  init(_ generated: GeneratedDigest.PartiallyGenerated) {
    self.init(
      overview: generated.overview,
      liked: generated.liked ?? [],
      disliked: generated.disliked ?? [],
      workload: generated.workload,
      grading: generated.grading
    )
  }
}
