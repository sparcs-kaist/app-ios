import Foundation
import Observation
import Factory
import BuddyDomain

@MainActor @Observable
final class ActivityCreationViewModel {
  var isSaving = false
  var errorMessage: String?
  var needsRefresh = false
  /// Whether the device can fill in the form from a description.
  private(set) var canParseDescriptions = false
  private(set) var isParsing = false
  /// Why the last description filled in nothing.
  private(set) var parseErrorMessage: String?

  @ObservationIgnored @Injected(
    \.foundationModelsUseCase
  ) private var foundationModelsUseCase: FoundationModelsUseCaseProtocol?

  func checkAvailability() async {
    canParseDescriptions = await foundationModelsUseCase?.isAvailable() ?? false
  }

  /// Reads `description` into the form's fields, or `nil` when it can't.
  func parse(_ description: String) async -> ParsedActivity? {
    guard let foundationModelsUseCase, !isParsing else { return nil }
    isParsing = true
    defer { isParsing = false }
    parseErrorMessage = nil
    do {
      return try await foundationModelsUseCase.parseActivity(description, today: .today)
    } catch is CancellationError {
      return nil
    } catch {
      parseErrorMessage = Self.message(for: error as? ActivityParsingError ?? .failed)
      return nil
    }
  }

  func clearParseError() {
    parseErrorMessage = nil
  }

  private static func message(for error: ActivityParsingError) -> String {
    switch error {
    case .unavailable:
      String(localized: "Apple Intelligence isn't available right now. Check that it's turned on in Settings, then try again.", bundle: .module)
    case .unsafeRequest:
      String(localized: "This description can't be used. Try describing the activity differently.", bundle: .module)
    case .nothingFound:
      String(localized: "Couldn't find an activity in that. Try including what it is, the day and the time.", bundle: .module)
    case .failed:
      String(localized: "Couldn't fill in the activity. Please try again.", bundle: .module)
    }
  }

  func save(
    draft: TimetableActivityDraft,
    onSave: (TimetableActivityDraft) async throws -> Void,
    onRefresh: () async throws -> Void
  ) async -> Bool {
    guard !isSaving else { return false }
    isSaving = true
    defer { isSaving = false }
    errorMessage = nil
    do {
      if needsRefresh { try await onRefresh() }
      else { try await onSave(draft) }
      return true
    } catch TimetableActivityError.refreshRequired {
      // The mutation succeeded. Retrying must fetch, never submit a duplicate.
      needsRefresh = true
      errorMessage = TimetableActivityError.refreshRequired.localizedDescription
    } catch {
      errorMessage = error.localizedDescription
    }
    return false
  }
}
