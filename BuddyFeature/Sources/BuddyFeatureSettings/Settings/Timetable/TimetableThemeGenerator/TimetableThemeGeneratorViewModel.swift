//
//  TimetableThemeGeneratorViewModel.swift
//  BuddyFeature
//
//  Created by Soongyu Kwon on 16/09/2026.
//

import Foundation
import Observation
import Factory
import BuddyDomain

enum TimetableThemeGeneratorViewState: Equatable {
  case idle
  /// The model is writing. `previewTheme` fills in underneath as it goes, so
  /// this state is shown both with and without a theme on screen.
  case generating
  case ready
  case failed(message: String)
}

/// Turns a description into a theme with the on-device model.
///
/// Owned by the editor rather than the sheet, because the editor needs the
/// availability answer to decide whether to offer the feature at all, and
/// keeping one instance means re-opening the sheet still shows the last theme
/// it generated.
@MainActor
@Observable
final class TimetableThemeGeneratorViewModel {
  /// A theme carries at most sixteen colours, and the model is asked for all
  /// sixteen by name.
  private static let cellCount = 16

  /// Long enough for a sentence, short enough that the field stays a brief.
  static let maximumDescriptionLength = 120

  var description: String = ""
  private(set) var viewState: TimetableThemeGeneratorViewState = .idle
  private(set) var previewTheme: TimetableTheme?
  /// Nothing is offered until the model answers for itself, so the entry point
  /// never appears on a device that cannot use it.
  private(set) var isModelAvailable = false
  /// Bumped by ``requestGeneration()``. The view drives generation off this
  /// with `task(id:)`, which cancels the model mid-sentence when the sheet is
  /// dismissed or the description is regenerated.
  private(set) var requestID = 0
  /// Rolled once per attempt and held for its duration, so the model and the
  /// palette both vary between attempts while the preview stays steady as the
  /// brief streams in.
  private(set) var variation: UInt64 = 0

  @ObservationIgnored
  @Injected(\.foundationModelsUseCase) private var foundationModelsUseCase: FoundationModelsUseCaseProtocol?

  var canGenerate: Bool {
    !description.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
  }

  func refreshAvailability() async {
    guard let foundationModelsUseCase else {
      isModelAvailable = false
      return
    }
    isModelAvailable = await foundationModelsUseCase.isAvailable()
  }

  func requestGeneration() {
    guard canGenerate else { return }
    variation = UInt64.random(in: .min ... .max)
    requestID += 1
  }

  /// Streams a brief and rebuilds the preview each time enough of it has
  /// arrived to draw. `baseTheme` supplies the identity being edited and the
  /// name to keep if the model doesn't offer one.
  func generate(basedOn baseTheme: TimetableTheme) async {
    guard let foundationModelsUseCase else {
      viewState = .failed(message: Self.message(for: TimetableThemeGenerationError.unavailable))
      return
    }
    let request = description.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !request.isEmpty else {
      viewState = .idle
      return
    }

    viewState = .generating
    previewTheme = nil

    var latest = TimetableThemeBrief()
    do {
      let briefs = await foundationModelsUseCase.streamThemeBrief(
        describing: request,
        variation: variation
      )
      for try await brief in briefs {
        try Task.checkCancellation()
        latest = brief
        // Half-written colours are dropped rather than drawn, so the preview
        // lands once per finished anchor instead of once per token.
        if let theme = theme(from: brief, basedOn: baseTheme) {
          previewTheme = theme
        }
      }
      try Task.checkCancellation()
      guard let theme = theme(from: latest, basedOn: baseTheme) else {
        throw TimetableThemeGenerationError.incomplete
      }
      previewTheme = theme
      viewState = .ready
    } catch is CancellationError {
      // The sheet is going away, or another run is already starting: leaving
      // the state alone avoids a failure flashing up on the way out.
    } catch {
      guard !Task.isCancelled else { return }
      previewTheme = nil
      viewState = .failed(message: Self.message(for: error))
    }
  }

  /// Puts the editor back to an empty field, so the next time the sheet opens
  /// it isn't showing the last theme as though it were about to be applied.
  func reset() {
    description = ""
    previewTheme = nil
    viewState = .idle
  }

  private func theme(
    from brief: TimetableThemeBrief,
    basedOn baseTheme: TimetableTheme
  ) -> TimetableTheme? {
    // The grid colour is generated before the blocks, so the preview settles
    // into its light or dark appearance first and then fills in, rather than
    // being redrawn the other way round partway through.
    guard let palette = TimetablePalette.derived(
      from: brief,
      cellCount: Self.cellCount
    ) else { return nil }

    return TimetableTheme(
      id: baseTheme.id,
      name: Self.name(from: brief.name) ?? baseTheme.name,
      hexColors: palette.colors,
      textColorHex: palette.text,
      separatorColorHex: palette.separator,
      backgroundColorHex: palette.background,
      gridLabelColorHex: palette.gridLabel
    )
  }

  /// The model is asked for at most three words; this is what stops it from
  /// writing a sentence into the name field.
  private static func name(from generated: String?) -> String? {
    guard let generated else { return nil }
    let trimmed = generated
      .trimmingCharacters(in: .whitespacesAndNewlines)
      .trimmingCharacters(in: CharacterSet(charactersIn: "\"'“”‘’"))
    guard !trimmed.isEmpty else { return nil }
    return String(trimmed.prefix(32))
  }

  private static func message(for error: any Error) -> String {
    switch error as? TimetableThemeGenerationError {
    case .unavailable:
      String(localized: "Apple Intelligence isn't available right now. Check that it is turned on and finished downloading.", bundle: .module)
    case .unsafeRequest:
      String(localized: "That description can't be used. Try describing a colour, a mood or a season instead.", bundle: .module)
    case .incomplete:
      String(localized: "No usable colours came back. Try describing the theme a different way.", bundle: .module)
    case .failed, nil:
      String(localized: "Could not generate a theme. Please try again.", bundle: .module)
    }
  }
}
