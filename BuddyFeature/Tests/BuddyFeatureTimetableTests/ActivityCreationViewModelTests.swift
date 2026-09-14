import Testing
import BuddyDomain
@testable import BuddyFeatureTimetable

@MainActor
struct ActivityCreationViewModelTests {
  @Test func successfulMutationWithFailedRefreshRetriesOnlyTheFetch() async {
    let model = ActivityCreationViewModel()
    let draft = TimetableActivityDraft(title: "Study", location: "", day: .mon, begin: 660, end: 720)
    var saveCount = 0
    var refreshCount = 0
    let first = await model.save(draft: draft, onSave: { _ in
      saveCount += 1
      throw TimetableActivityError.refreshRequired
    }, onRefresh: { refreshCount += 1 })
    #expect(!first)
    #expect(model.needsRefresh)
    #expect(!model.isSaving)
    let second = await model.save(draft: draft, onSave: { _ in saveCount += 1 }, onRefresh: { refreshCount += 1 })
    #expect(second)
    #expect(saveCount == 1)
    #expect(refreshCount == 1)
  }

  @Test func failedMutationKeepsDraftEditableAndAllowsRetry() async {
    let model = ActivityCreationViewModel()
    let draft = TimetableActivityDraft(title: "Study", location: "", day: .mon, begin: 660, end: 720)
    let first = await model.save(draft: draft, onSave: { _ in throw NetworkError.noConnection }, onRefresh: {})
    #expect(!first)
    #expect(!model.needsRefresh)
    #expect(model.errorMessage != nil)
    let second = await model.save(draft: draft, onSave: { saved in #expect(saved == draft) }, onRefresh: {})
    #expect(second)
    #expect(model.errorMessage == nil)
  }
}
