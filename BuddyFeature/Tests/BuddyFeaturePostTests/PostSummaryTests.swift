//
//  PostSummaryTests.swift
//  BuddyFeature
//
//  Created by Soongyu Kwon on 25/10/2026.
//

import Foundation
import Testing
import BuddyTestSupport
@testable import BuddyFeaturePost
@testable import BuddyDomain

extension PostFeatureTests {
  @Suite("Post summary")
  @MainActor
  struct PostSummaryTests {
    /// A Tiptap post with `length` letters of text.
    private func post(length: Int) -> AraPost {
      let text = String(repeating: "가", count: length)
      return AraFixtures.post(
        id: 1,
        content: #"{"type":"doc","content":[{"type":"paragraph","content":[{"type":"text","text":"\#(text)"}]}]}"#
      )
    }

    /// A view model for `post` with its body parsed and the model's availability known.
    private func viewModel(for post: AraPost, model: MockFoundationModelsUseCase) async throws -> PostViewModel {
      setupPostTestDependencies(foundationModelsUseCase: model)
      let viewModel = PostViewModel(post: post)
      await viewModel.prepareContentBody()
      let isAvailable = await model.isAvailable()
      try await waitUntil { viewModel.isFoundationModelsAvailable == isAvailable }
      return viewModel
    }

    @Test func offersSummariesOnlyForLongPostsOnCapableDevices() async throws {
      defer { tearDownPostTestDependencies() }
      let model = MockFoundationModelsUseCase()

      await model.stubSummary(isAvailable: true)
      #expect(try await viewModel(for: post(length: 250), model: model).canSummarise)
      #expect(try await viewModel(for: post(length: 50), model: model).canSummarise == false)

      await model.stubSummary(isAvailable: false)
      #expect(try await viewModel(for: post(length: 250), model: model).canSummarise == false)
    }

    @Test func showsTheFinishedSummary() async throws {
      defer { tearDownPostTestDependencies() }
      let model = MockFoundationModelsUseCase()
      await model.stubSummary(summary: "  A short summary.\n")
      let viewModel = try await viewModel(for: post(length: 250), model: model)

      viewModel.summarise()
      #expect(viewModel.summaryPhase == .summarising(""))
      try await waitUntil { viewModel.summaryPhase == .finished("A short summary.") }
    }

    @Test func showsWhyItFailedAndTriesAgain() async throws {
      defer { tearDownPostTestDependencies() }
      let model = MockFoundationModelsUseCase()
      await model.stubSummary(error: SummarisationError.unsafeContent)
      let viewModel = try await viewModel(for: post(length: 250), model: model)

      viewModel.summarise()
      try await waitUntil {
        viewModel.summaryPhase == .failed(message: SummarisationError.unsafeContent.localizedDescription)
      }

      await model.stubSummary(summary: "Second time lucky.")
      viewModel.summarise()
      try await waitUntil { viewModel.summaryPhase == .finished("Second time lucky.") }
    }

    @Test func anEmptySummaryIsAFailure() async throws {
      defer { tearDownPostTestDependencies() }
      let model = MockFoundationModelsUseCase()
      await model.stubSummary(summary: " \n ")
      let viewModel = try await viewModel(for: post(length: 250), model: model)

      viewModel.summarise()
      try await waitUntil {
        viewModel.summaryPhase == .failed(message: SummarisationError.failed.localizedDescription)
      }
    }

    @Test func countsHTMLTextWithoutItsMarkup() {
      let body = PostBody.html(#"<p class="lead">Hello <b>there</b></p>"#, baseURL: URL(string: "https://example.com")!)
      #expect(body.textLength == "Hellothere".count)
    }

    /// Polls the main actor until `condition` holds, for work the view model starts on its own.
    private func waitUntil(_ condition: () -> Bool) async throws {
      for _ in 0..<200 where !condition() {
        try await Task.sleep(for: .milliseconds(10))
      }
      #expect(condition())
    }
  }
}
