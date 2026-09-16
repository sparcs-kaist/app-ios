//
//  FoundationModelsUseCase+TimetableTheme.swift
//  BuddyDataiOS
//
//  Created by Soongyu Kwon on 16/09/2026.
//

import Foundation
import FoundationModels
import BuddyDomain

/// The shape the model fills in.
///
/// The order of the properties matters: guided generation produces them in the
/// order they are declared, so by the time a snapshot carries a colour it also
/// carries the name and the appearance. A preview built from that snapshot
/// never has to flip from light to dark after it has been drawn.
@Generable(description: "A colour scheme for a weekly university timetable")
private struct GeneratedTheme {
  @Guide(description: "A short, evocative name for the theme. At most three words, no quotation marks.")
  var name: String

  @Guide(description: "Whether the timetable should look light or dark overall")
  var appearance: GeneratedAppearance

  @Guide(
    description: "The colours the description is made of, most important first, each six hexadecimal digits in RRGGBB order with no leading '#'.",
    .count(3...6)
  )
  var colors: [String]
}

@Generable
private enum GeneratedAppearance {
  case light
  case dark
}

extension FoundationModelsUseCase {
  /// Model-facing, so deliberately not localised: the instructions describe a
  /// data format rather than anything a person reads. Names come back in the
  /// language the description was written in because the model is told to
  /// match it.
  ///
  /// No proper nouns and no worked examples in here. Both were tried, and both
  /// leaked: naming clubs to demonstrate recalling a club's colours had the
  /// model answering with the club from the instructions whatever anyone
  /// typed.
  private static let themeInstructions = """
    You design colour schemes for a weekly university timetable grid.

    Answer with the colours the description is made of — three to six of them, \
    most important first. The app builds the whole grid out of those colours, \
    so give it the colours and nothing else.

    If the description names a colour, or names a thing that has colours of its \
    own such as a kit, a flag or a fruit, use only those colours. If it comes \
    down to one colour, give shades of that one colour and nothing besides.

    If it is a mood or a feeling rather than a colour, it has no colours of its \
    own, so give several different ones that suit it instead of narrowing it to \
    one.

    Choose the appearance the description implies: a pale or white subject is \
    light, and a black or night-time one is dark.

    Write every colour as exactly six hexadecimal digits in RRGGBB order, with \
    no leading '#'. The first pair is red, the second green, the third blue: a \
    green colour has the middle pair highest, a blue colour the last pair \
    highest. Check each colour you write against that.

    Name the theme in the same language the description is written in.
    """

  /// A description far longer than this is a paste, not a brief, and only eats
  /// into the context the instructions need.
  private static let maximumDescriptionLength = 240

  public func streamThemeBrief(
    describing description: String,
    variation: UInt64
  ) -> AsyncThrowingStream<TimetableThemeBrief, any Error> {
    let request = String(
      description
        .trimmingCharacters(in: .whitespacesAndNewlines)
        .prefix(Self.maximumDescriptionLength)
    )

    return AsyncThrowingStream { continuation in
      // The session is created and consumed entirely inside this task, so it
      // never crosses an isolation boundary. The task inherits the actor, and
      // awaiting the stream lets other callers — an availability check, say —
      // run in between.
      let task = Task {
        guard case .available = SystemLanguageModel.default.availability else {
          continuation.finish(throwing: TimetableThemeGenerationError.unavailable)
          return
        }
        guard !request.isEmpty else {
          continuation.finish(throwing: TimetableThemeGenerationError.incomplete)
          return
        }

        let session = LanguageModelSession(
          model: .default,
          instructions: Self.themeInstructions
        )

        do {
          let stream = session.streamResponse(
            to: "Design a timetable colour scheme for this description: \(request)",
            generating: GeneratedTheme.self,
            // Left to its default the model answers the same description the
            // same way every time, so asking again returned the theme that had
            // just been turned down. A fresh seed per attempt is what makes a
            // second ask a second opinion.
            options: GenerationOptions(
              sampling: .random(probabilityThreshold: 0.92, seed: variation),
              temperature: 0.9
            )
          )
          for try await snapshot in stream {
            continuation.yield(TimetableThemeBrief(snapshot.content))
          }
          continuation.finish()
        } catch is CancellationError {
          continuation.finish()
        } catch {
          continuation.finish(throwing: Self.generationError(for: error))
        }
      }
      continuation.onTermination = { _ in task.cancel() }
    }
  }

  /// A guardrail violation or a refusal is the person's description being
  /// turned down, which is worth saying; everything else is a failure they can
  /// simply retry.
  ///
  /// Two error types to match because the framework renamed its own: iOS 27
  /// throws `LanguageModelError`, and this package still deploys to iOS 26,
  /// which throws the session's `GenerationError`.
  private static func generationError(for error: any Error) -> TimetableThemeGenerationError {
    if #available(iOS 27, *), let error = error as? LanguageModelError {
      switch error {
      case .guardrailViolation, .refusal: return .unsafeRequest
      default: return .failed
      }
    }
    if let error = error as? LanguageModelSession.GenerationError {
      switch error {
      case .guardrailViolation, .refusal: return .unsafeRequest
      default: return .failed
      }
    }
    return .failed
  }
}

private extension TimetableThemeBrief {
  /// Adapts a snapshot of the generated type, which has every property
  /// optional while the model is still writing.
  init(_ generated: GeneratedTheme.PartiallyGenerated) {
    self.init(
      name: generated.name,
      appearance: generated.appearance.map { $0 == .light ? .light : .dark },
      anchorHexColors: generated.colors ?? []
    )
  }
}
