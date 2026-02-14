//
//  PostViewModelTests.swift
//  BuddyFeature
//
//  Created by Codex on 13/02/2026.
//

import Testing
import SwiftUI
import BuddyTestSupport
@testable import BuddyFeaturePost
@testable import BuddyDomain

@Suite("PostViewModel Tests")
struct PostViewModelTests {

  @Test("Initial alert state is empty")
  @MainActor
  func initialAlertState() {
    setupPostTestDependencies()
    let viewModel = PostViewModel(post: AraPost.mock)

    #expect(viewModel.alertState == nil)
    #expect(viewModel.isAlertPresented == false)

    tearDownPostTestDependencies()
  }

  @Test("fetchPost success updates post without presenting alert")
  @MainActor
  func fetchPostSuccess() async {
    let mockBoardUseCase = MockAraBoardUseCase()
    mockBoardUseCase.fetchPostResult = .success(AraPost.mockList[1])
    setupPostTestDependencies(araBoardUseCase: mockBoardUseCase)

    let viewModel = PostViewModel(post: AraPost.mock)

    await viewModel.fetchPost()

    #expect(mockBoardUseCase.fetchPostCallCount == 1)
    #expect(mockBoardUseCase.lastFetchPostID == AraPost.mock.id)
    #expect(viewModel.post.id == AraPost.mockList[1].id)
    #expect(viewModel.alertState == nil)
    #expect(viewModel.isAlertPresented == false)

    tearDownPostTestDependencies()
  }

  @Test("fetchPost failure presents alert state")
  @MainActor
  func fetchPostFailurePresentsAlert() async {
    let mockBoardUseCase = MockAraBoardUseCase()
    mockBoardUseCase.fetchPostResult = .failure(TestError.testFailure)
    setupPostTestDependencies(araBoardUseCase: mockBoardUseCase)

    let viewModel = PostViewModel(post: AraPost.mock)

    await viewModel.fetchPost()

    #expect(mockBoardUseCase.fetchPostCallCount == 1)
    #expect(viewModel.isAlertPresented == true)
    #expect(viewModel.alertState?.title == "Unable to fetch post.")
    #expect(viewModel.alertState?.message.contains("Test failure") == true)

    tearDownPostTestDependencies()
  }

  @Test("writeComment appends comment and increments count")
  @MainActor
  func writeCommentSuccess() async throws {
    let mockCommentUseCase = MockAraCommentUseCase()
    let postedComment = AraPostComment.mock
    mockCommentUseCase.writeCommentResult = .success(postedComment)
    setupPostTestDependencies(araCommentUseCase: mockCommentUseCase)

    var initialPost = AraPost.mock
    initialPost.comments = []
    initialPost.commentCount = 0
    let viewModel = PostViewModel(post: initialPost)

    let createdComment = try await viewModel.writeComment(content: "Hello")

    #expect(createdComment.id == postedComment.id)
    #expect(viewModel.post.comments.count == 1)
    #expect(viewModel.post.commentCount == 1)
    #expect(viewModel.post.comments[0].isMine == true)

    tearDownPostTestDependencies()
  }

  @Test("deleteComment rolls back content when deletion fails")
  @MainActor
  func deleteCommentRollbackOnFailure() async {
    let mockCommentUseCase = MockAraCommentUseCase()
    mockCommentUseCase.deleteCommentResult = .failure(TestError.testFailure)
    setupPostTestDependencies(araCommentUseCase: mockCommentUseCase)

    let viewModel = PostViewModel(post: AraPost.mock)
    var comment = AraPostComment.mock
    let previousContent = comment.content
    let binding = Binding(get: { comment }, set: { comment = $0 })

    await viewModel.deleteComment(comment: binding)

    #expect(comment.content == previousContent)

    tearDownPostTestDependencies()
  }
}
