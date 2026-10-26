//
//  AuthorBlockTests.swift
//  BuddyFeature
//
//  Created by Soongyu Kwon on 26/10/2026.
//

import Foundation
import Testing
import BuddyTestSupport
@testable import BuddyFeaturePost
@testable import BuddyDomain

extension PostFeatureTests {
  @Suite("Blocking authors")
  struct AuthorBlockTests {
    private func author(id: String, isBlocked: Bool?) -> AraPostAuthor {
      AraPostAuthor(
        id: id,
        username: "buddy",
        profile: AraPostAuthorProfile(id: id, profilePictureURL: nil, nickname: "Buddy", isOfficial: nil, isSchoolAdmin: nil),
        isBlocked: isBlocked
      )
    }

    @Test("An author named by their nickname can be blocked by their account ID")
    func nicknameAuthor() {
      #expect(author(id: "4821", isBlocked: false).blockableUserID == 4821)
      #expect(author(id: "4821", isBlocked: true).blockableUserID == 4821)
    }

    /// Ara sends anonymous authors a per-post hash, and real-name authors a number that isn't
    /// their account, both without `is_blocked`.
    @Test("Anonymous and real-name authors can't be blocked")
    func disguisedAuthors() {
      #expect(author(id: "3f9a0c1e8b7d", isBlocked: nil).blockableUserID == nil)
      #expect(author(id: "90210", isBlocked: nil).blockableUserID == nil)
    }

    @Test("Content hidden for a blocked author says so")
    func hiddenForBlock() {
      let blocked = AraPostComment(
        id: 1,
        isHidden: true,
        hiddenReason: [AraHiddenReason.blockedUserContent],
        overrideHidden: true,
        author: author(id: "4821", isBlocked: true),
        comments: [],
        createdAt: .now,
        upvotes: 0,
        downvotes: 0,
        parentPost: 1,
        parentComment: nil
      )
      let deleted = AraPostComment(
        id: 2,
        isHidden: false,
        hiddenReason: [],
        overrideHidden: nil,
        author: author(id: "4821", isBlocked: false),
        comments: [],
        createdAt: .now,
        upvotes: 0,
        downvotes: 0,
        parentPost: 1,
        parentComment: nil
      )

      #expect(blocked.isHiddenForBlockedAuthor)
      #expect(!deleted.isHiddenForBlockedAuthor)
    }

    @Test("Blocking an author blocks their account and reloads the post")
    @MainActor
    func blockReloadsPost() async {
      let board = MockAraBoardUseCase()
      let users = MockAraUserRepository()
      setupPostTestDependencies(araBoardUseCase: board, araUserRepository: users)
      defer { tearDownPostTestDependencies() }

      let viewModel = PostViewModel(post: AraPost.mock)
      await viewModel.setAuthorBlocked(AraPost.mock.author, blocked: true)

      #expect(users.blockedUserIDs == [984])
      #expect(board.fetchPostCallCount == 1)
      #expect(!viewModel.isAlertPresented)
    }

    @Test("An eleventh block in a day explains Ara's limit")
    @MainActor
    func dailyLimit() async {
      let board = MockAraBoardUseCase()
      let users = MockAraUserRepository()
      users.blockResult = .failure(NetworkError.serverError(statusCode: 403))
      setupPostTestDependencies(araBoardUseCase: board, araUserRepository: users)
      defer { tearDownPostTestDependencies() }

      let viewModel = PostViewModel(post: AraPost.mock)
      await viewModel.setAuthorBlocked(AraPost.mock.author, blocked: true)

      #expect(viewModel.isAlertPresented)
      // Ara's reason, rather than "Server error (403)".
      let generic = NetworkError.serverError(statusCode: 403).localizedDescription
      #expect(viewModel.alertState?.message != nil)
      #expect(viewModel.alertState?.message != generic)
      #expect(board.fetchPostCallCount == 0)
    }

    @Test("Unblocking from the list takes the person off it")
    @MainActor
    func unblockFromList() async {
      let users = MockAraUserRepository()
      let first = AraBlockedUser(id: 1, nickname: "One", profilePictureURL: nil)
      let second = AraBlockedUser(id: 2, nickname: "Two", profilePictureURL: nil)
      users.fetchBlockedUsersResult = .success([first, second])
      setupPostTestDependencies(araUserRepository: users)
      defer { tearDownPostTestDependencies() }

      let model = BlockedUsersModel()
      await model.load()
      await model.unblock(first)

      #expect(users.unblockedUserIDs == [1])
      #expect(model.state == .loaded([second]))
    }

    @Test("A failed unblock puts the person back where they were")
    @MainActor
    func failedUnblock() async {
      let users = MockAraUserRepository()
      let first = AraBlockedUser(id: 1, nickname: "One", profilePictureURL: nil)
      let second = AraBlockedUser(id: 2, nickname: "Two", profilePictureURL: nil)
      users.fetchBlockedUsersResult = .success([first, second])
      users.blockResult = .failure(NetworkError.serverError(statusCode: 500))
      setupPostTestDependencies(araUserRepository: users)
      defer { tearDownPostTestDependencies() }

      let model = BlockedUsersModel()
      await model.load()
      await model.unblock(first)

      #expect(model.state == .loaded([first, second]))
      #expect(model.isAlertPresented)
    }
  }
}
