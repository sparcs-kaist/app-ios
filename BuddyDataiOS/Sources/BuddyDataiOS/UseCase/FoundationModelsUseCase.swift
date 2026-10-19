//
//  FoundationModelsUseCase.swift
//  soap
//
//  Created by Soongyu Kwon on 14/08/2025.
//

import Foundation
import FoundationModels
import BuddyDomain

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
      point.
      """
    }
    return """
      \(task)

      Write plain sentences, without a heading or bullet points. Write in \
      \(language), whatever language the text is in.
      """
  }

  /// A review summary sits right above the review, so it must be clearly shorter.
  private static func summaryWordLimit(for kind: SummaryKind) -> Int {
    switch kind {
    case .lectureReview: 40
    case .post: 50
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
        let session = LanguageModelSession(
          model: model,
          instructions: Self.summaryInstructions(for: kind, language: language)
        )
        do {
          let stream = session.streamResponse(
            // The language repeated from the instructions: text in another
            // language otherwise pulls the summary into its own.
            to: "Summarise this in \(language), in at most \(Self.summaryWordLimit(for: kind)) words:\n\(request)",
            options: GenerationOptions(samplingMode: .greedy)
          )
          for try await snapshot in stream {
            continuation.yield(snapshot.content)
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

  public init() {
    
  }
}

