//
//  FoundationModelsUseCase.swift
//  soap
//
//  Created by Soongyu Kwon on 14/08/2025.
//

import Foundation
import FoundationModels
import BuddyDomain
import BuddyDataCore

/// A post's summary in the shape the model fills in: a line saying what the post is, then the
/// few facts a reader acts on. A fixed shape keeps the model from retelling the post in full.
@Generable(description: "A short summary of a post on a university community board")
private struct GeneratedPostSummary {
  @Guide(description: "One short sentence saying what the post is, such as a job offer, an event or a question. Never start with 'This post' or 'The post'.")
  var gist: String

  @Guide(description: "The facts a reader would act on, each a short phrase: when, where, how much, who can take part, and what to do or whom to contact. Most important first. Empty if the post has none.", .maximumCount(4))
  var keyFacts: [String]
}

public actor FoundationModelsUseCase: FoundationModelsUseCaseProtocol {
  public func isAvailable() async -> Bool {
    SystemLanguageModel.default.isAvailable
  }

  /// Model-facing, so deliberately not localised: the language to write in is
  /// named instead.
  private static func summaryInstructions(for kind: SummaryKind, language: String) -> String {
    let task = switch kind {
    case .lectureReview:
      """
      You summarise one student's review of a university lecture, for someone \
      deciding whether to take it. Keep what the review says about the \
      lecturing, the workload, the exams and assignments, the grading, and any \
      advice it gives. Leave out remarks that say nothing about the lecture.
      """
    case .post:
      """
      You summarise a post on a university community board, for someone \
      deciding whether to read it in full. Keep the key facts: subjects, names, \
      dates, times, places and numbers. Leave out greetings unless they are the \
      point. Copy every number, amount and unit exactly as the post writes it: \
      Korean amounts such as 3만원 mean 30,000 won, so keep 3만원 rather than \
      converting it.
      """
    }
    let form = switch kind {
    case .lectureReview: "Write plain sentences, without a heading or bullet points."
    case .post: "Keep every phrase short, and never repeat a fact."
    }
    return """
      \(task)

      \(form) Write in \(language), whatever language the text is in.
      """
  }

  /// For a text too long to summarise in one go: notes on one part of it, read
  /// together afterwards. In the summary's language, as notes in another
  /// language pull the summary into theirs. Model-facing, so not localised.
  private static func partNotesInstructions(language: String) -> String {
    """
    You take notes on one part of a longer text, for someone who will \
    summarise the whole text later. Write at most five short bullet points in \
    \(language) with the key facts in this part: subjects, names, dates, \
    times, places, numbers, and anything the reader is asked to do. Leave out \
    greetings.
    """
  }

  /// Tokens kept back from the context for the instructions and the response.
  private static let summaryReservedTokens = 800
  /// Paragraphs past this many characters are cut into pieces, so one long
  /// paragraph can't overflow a part on its own.
  private static let maximumParagraphLength = 1_500

  /// A review summary sits right above the review, so it must be clearly shorter.
  private static func summaryWordLimit(for kind: SummaryKind) -> Int {
    switch kind {
    case .lectureReview: 40
    case .post: 60
    }
  }

  /// Summarising someone else's words is a transformation of them, so blunt or
  /// rude text is reworded rather than refused, as review notes are.
  public func streamSummary(of text: String, as kind: SummaryKind) -> AsyncThrowingStream<String, any Error> {
    let request = text.trimmingCharacters(in: .whitespacesAndNewlines)

    return AsyncThrowingStream { continuation in
      // As in `streamThemeBrief`, the session lives and dies inside this task.
      let task = Task {
        let model = SystemLanguageModel(guardrails: .permissiveContentTransformations)
        guard case .available = model.availability else {
          continuation.finish(throwing: SummarisationError.unavailable)
          return
        }
        guard !request.isEmpty else {
          continuation.finish(throwing: SummarisationError.failed)
          return
        }

        let language = Self.deviceLanguage(model: model)
        do {
          // A long post overflows the model's few thousand tokens, so it's read
          // a part at a time into notes, and the notes are summarised instead.
          let source = try await Self.fitting(request, model: model, language: language)
          let session = LanguageModelSession(
            model: model,
            instructions: Self.summaryInstructions(for: kind, language: language)
          )
          // The language repeated from the instructions: text in another language
          // otherwise pulls the summary into its own.
          let prompt = "Summarise this in \(language), in at most \(Self.summaryWordLimit(for: kind)) words:\n\(source)"
          switch kind {
          case .lectureReview:
            let stream = session.streamResponse(to: prompt, options: GenerationOptions(samplingMode: .greedy))
            for try await snapshot in stream {
              continuation.yield(snapshot.content)
            }
          case .post:
            let stream = session.streamResponse(
              to: prompt,
              generating: GeneratedPostSummary.self,
              options: GenerationOptions(samplingMode: .greedy)
            )
            for try await snapshot in stream {
              continuation.yield(Self.text(of: snapshot.content))
            }
          }
          continuation.finish()
        } catch is CancellationError {
          continuation.finish()
        } catch {
          continuation.finish(
            throwing: Self.isGuardrailViolation(error) ? SummarisationError.unsafeContent : SummarisationError.failed
          )
        }
      }
      continuation.onTermination = { _ in task.cancel() }
    }
  }

  /// A post summary as text: the gist, then each key fact on a line of its own.
  private static func text(of summary: GeneratedPostSummary.PartiallyGenerated) -> String {
    let facts = (summary.keyFacts ?? [])
      .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
      .filter { !$0.isEmpty }
      .map { "• \($0)" }
    return ([summary.gist?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""] + facts)
      .filter { !$0.isEmpty }
      .joined(separator: "\n")
  }

  /// `text` itself when it fits the context, or else notes on its parts, read
  /// in order. Only the first few parts are read, as reading every part of a
  /// very long text would take minutes.
  private static func fitting(_ text: String, model: SystemLanguageModel, language: String) async throws -> String {
    let budget = max(model.contextSize - summaryReservedTokens, 1_000)
    guard await tokenCount(text) > budget else { return text }

    let parts = await LectureReviewBatching.batches(of: paragraphs(of: text), budget: budget, cost: tokenCount)
    var notes: [String] = []
    for part in parts {
      try Task.checkCancellation()
      let session = LanguageModelSession(model: model, instructions: partNotesInstructions(language: language))
      let response = try await session.respond(
        to: "Take notes on this part:\n\(part.joined(separator: "\n"))",
        options: GenerationOptions(samplingMode: .greedy)
      )
      notes.append(response.content)
    }
    return notes.joined(separator: "\n")
  }

  /// The text's non-empty lines, each cut into pieces of at most
  /// ``maximumParagraphLength`` characters.
  static func paragraphs(of text: String) -> [String] {
    text.split(whereSeparator: \.isNewline).flatMap { line -> [String] in
      let line = line.trimmingCharacters(in: .whitespaces)
      var pieces: [String] = []
      var rest = Substring(line)
      while !rest.isEmpty {
        pieces.append(String(rest.prefix(maximumParagraphLength)))
        rest = rest.dropFirst(maximumParagraphLength)
      }
      return pieces
    }
  }

  public init() {
    
  }
}

