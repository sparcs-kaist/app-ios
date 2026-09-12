import Foundation
import Observation
import BuddyDomain

@MainActor @Observable
final class ActivityCreationViewModel {
  var isSaving = false
  var errorMessage: String?
  var needsRefresh = false

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
