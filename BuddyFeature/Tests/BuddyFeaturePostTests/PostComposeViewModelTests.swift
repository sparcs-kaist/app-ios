//
//  PostComposeViewModelTests.swift
//  BuddyFeature
//
//  Created by Soongyu Kwon on 24/10/2026.
//

import Foundation
import Testing
import TiptapKit
import BuddyTestSupport
@testable import BuddyFeaturePost
@testable import BuddyDomain

extension PostFeatureTests {
  @Suite("Post composer")
  @MainActor
  struct PostComposeViewModelTests {
    // MARK: - Name type

    @Test func startsAnonymousOnlyWhereTheBoardAllowsIt() {
      setupPostTestDependencies()
      defer { tearDownPostTestDependencies() }

      let talk = PostComposeViewModel(board: AraFixtures.board())
      #expect(talk.writeAsAnonymous)
      #expect(talk.canChooseAnonymity)

      let market = PostComposeViewModel(board: AraFixtures.market)
      #expect(!market.writeAsAnonymous)
      #expect(!market.canChooseAnonymity)
    }

    @Test(arguments: [
      ([AraPostNicknameType.regular, .anonymous], true, AraPostNicknameType.anonymous),
      ([.regular, .anonymous], false, .regular),
      // Market: anonymity can't be chosen, so a stale toggle doesn't get the post rejected.
      ([.regular], true, .regular),
      // KAIST News and Messages to the School.
      ([.realName], true, .realName),
    ])
    func sendsANameTheBoardAllows(allowed: [AraPostNicknameType], anonymous: Bool, expected: AraPostNicknameType) async throws {
      let useCase = MockAraBoardUseCase()
      useCase.writePostResult = .success(())
      setupPostTestDependencies(araBoardUseCase: useCase)
      defer { tearDownPostTestDependencies() }

      let viewModel = PostComposeViewModel(board: AraFixtures.board(nameTypes: allowed))
      viewModel.title = "Title"
      viewModel.writeAsAnonymous = anonymous
      try await viewModel.submit()

      #expect(useCase.writtenPosts.first?.nicknameType == expected)
    }

    // MARK: - Market

    @Test func clampsThePrice() {
      setupPostTestDependencies()
      defer { tearDownPostTestDependencies() }

      let viewModel = PostComposeViewModel(board: AraFixtures.market)
      viewModel.price = -500
      #expect(viewModel.price == 0)
      viewModel.price = 10_000_000_000_000
      #expect(viewModel.price == 999_999_999_999)
    }

    @Test func sendsAListingOnlyOnMarket() async throws {
      let useCase = MockAraBoardUseCase()
      useCase.writePostResult = .success(())
      setupPostTestDependencies(araBoardUseCase: useCase)
      defer { tearDownPostTestDependencies() }

      let market = PostComposeViewModel(board: AraFixtures.market)
      market.title = "Desk lamp"
      market.price = 12_000
      try await market.submit()

      let talk = PostComposeViewModel(board: AraFixtures.board())
      talk.title = "Hello"
      talk.price = 12_000
      try await talk.submit()

      #expect(useCase.writtenPosts.first?.marketListing == AraMarketListing(price: 12_000))
      #expect(useCase.writtenPosts.last?.marketListing == nil)
    }

    // MARK: - Files

    @Test func attachesAPickedFileAndRemovesItsCopy() throws {
      setupPostTestDependencies()
      defer { tearDownPostTestDependencies() }

      let picked = try Self.temporaryFile(named: "Syllabus.pdf", bytes: 2_048)
      let viewModel = PostComposeViewModel(board: AraFixtures.board())
      try viewModel.addFiles([picked])

      let file = try #require(viewModel.files.first)
      #expect(file.name == "Syllabus.pdf")
      #expect(file.size == 2_048)
      #expect(file.mimeType == "application/pdf")
      guard case .local(let copy) = file.source else {
        Issue.record("A picked file should be a local copy")
        return
      }
      #expect(copy != picked)
      #expect(FileManager.default.fileExists(atPath: copy.path(percentEncoded: false)))

      viewModel.removeFile(file)
      #expect(viewModel.files.isEmpty)
      #expect(!FileManager.default.fileExists(atPath: copy.path(percentEncoded: false)))
    }

    @Test func uploadsPickedFilesWithThePost() async throws {
      let useCase = MockAraBoardUseCase()
      useCase.writePostResult = .success(())
      useCase.uploadFileResult = .success(
        AraAttachment(id: 99, file: nil, size: 2_048, mimeType: "application/pdf", createdAt: .now)
      )
      setupPostTestDependencies(araBoardUseCase: useCase)
      defer { tearDownPostTestDependencies() }

      let viewModel = PostComposeViewModel(board: AraFixtures.board())
      viewModel.title = "Notes"
      try viewModel.addFiles([try Self.temporaryFile(named: "Notes.pdf", bytes: 2_048)])
      try await viewModel.submit()

      #expect(useCase.uploadedFiles.map(\.fileName) == ["Notes.pdf"])
      #expect(useCase.uploadedFiles.first?.size == 2_048)
      #expect(useCase.writtenPosts.first?.attachmentIDs == [99])
    }

    @Test func editingListsFilesAndPhotosNotInTheText() {
      setupPostTestDependencies()
      defer { tearDownPostTestDependencies() }

      let post = AraFixtures.post(
        id: 1,
        board: AraFixtures.board(),
        content: #"{"type":"doc","content":[{"type":"attachmentImage","attrs":{"src":"https://sparcs-newara.s3.amazonaws.com/files/inline.jpg"}}]}"#,
        attachments: [
          AraFixtures.attachment(id: 1, fileName: "inline.jpg", mimeType: "image/jpeg"),
          AraFixtures.attachment(id: 2, fileName: "room.jpg", mimeType: "image/jpeg"),
          AraFixtures.attachment(id: 3, fileName: "contract.pdf", mimeType: "application/pdf"),
        ]
      )
      let viewModel = PostComposeViewModel(editing: post, board: AraFixtures.board())

      #expect(viewModel.files.map(\.name) == ["room.jpg", "contract.pdf"])
    }

    @Test func editingKeepsListedFilesAndPhotosStillInTheText() {
      let post = AraFixtures.post(
        id: 1,
        attachments: [
          AraFixtures.attachment(id: 10, fileName: "kept.jpg", mimeType: "image/jpeg"),
          AraFixtures.attachment(id: 11, fileName: "removed.jpg", mimeType: "image/jpeg"),
          AraFixtures.attachment(id: 12, fileName: "old.pdf", mimeType: "application/pdf"),
        ]
      )
      // The text still shows one photo by id; the other was deleted from it.
      let document = TiptapDocument(content: [
        TiptapNode(type: .attachmentImage, attrs: ["data-attachment": .string("10")]),
      ])

      // The file list kept old.pdf (12) and gained a new upload (20).
      let ids = PostComposeViewModel.attachmentIDs(keptBy: document, from: post, files: [12, 20])
      #expect(ids == [12, 20, 10])
    }

    @Test func editingFindsPhotosWithoutAnAttachmentIDByTheirFile() {
      let post = AraFixtures.post(
        id: 1,
        attachments: [AraFixtures.attachment(id: 10, fileName: "old.jpg", mimeType: "image/jpeg")]
      )
      let document = TiptapDocument(content: [
        TiptapNode(type: .image, attrs: ["src": .string("https://sparcs-newara.s3.amazonaws.com/files/old.jpg")]),
      ])

      #expect(PostComposeViewModel.attachmentIDs(keptBy: document, from: post, files: []) == [10])
    }

    private static func temporaryFile(named name: String, bytes: Int) throws -> URL {
      let directory = FileManager.default.temporaryDirectory
        .appending(path: "PostComposeTests/\(UUID().uuidString)", directoryHint: .isDirectory)
      try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
      let url = directory.appending(path: name)
      try Data(count: bytes).write(to: url)
      return url
    }
  }
}
