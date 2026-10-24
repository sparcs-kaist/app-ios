//
//  AraFixtures.swift
//  BuddyFeature
//
//  Created by Soongyu Kwon on 24/10/2026.
//

import Foundation
@testable import BuddyDomain

/// Boards and posts shaped for one test each, built on the shared mocks.
enum AraFixtures {
  static let group = AraBoardGroup(id: 1, slug: "talk", name: LocalizedString(["en": "Talk", "ko": "자유"]))

  /// A board allowing `nameTypes`; Ara's flags for Talk are regular and anonymous.
  static func board(
    id: Int = 2,
    slug: String = "talk",
    nameTypes: [AraPostNicknameType] = [.regular, .anonymous],
    topics: [AraBoardTopic] = [],
    readable: Bool = true
  ) -> AraBoard {
    AraBoard(
      id: id,
      slug: slug,
      name: LocalizedString(["en": slug, "ko": slug]),
      group: group,
      topics: topics,
      isReadOnly: false,
      userReadable: readable,
      userWritable: true,
      nicknameTypes: nameTypes
    )
  }

  static var market: AraBoard { board(id: 7, slug: "market", nameTypes: [.regular]) }
  static var portalNotice: AraBoard { board(id: 1, slug: "portal-notice", nameTypes: [.regular]) }

  static func post(
    id: Int,
    board: AraBoard? = nil,
    title: String = "A post",
    content: String? = nil,
    attachments: [AraPostAttachment]? = [],
    readStatus: AraPost.ReadStatus? = .unread,
    marketListing: AraMarketListing? = nil
  ) -> AraPost {
    let mock = AraPost.mock
    return AraPost(
      id: id,
      isHidden: false,
      hiddenReason: [],
      overrideHidden: nil,
      topic: nil,
      board: board,
      title: title,
      author: mock.author,
      nameType: .regular,
      marketListing: marketListing,
      readStatus: readStatus,
      attachmentType: .none,
      communicationArticleStatus: nil,
      createdAt: mock.createdAt,
      isNSFW: false,
      isPolitical: false,
      views: 0,
      commentCount: 0,
      upvotes: 0,
      downvotes: 0,
      attachments: attachments,
      myCommentProfile: nil,
      isMine: true,
      comments: [],
      content: content,
      myScrap: false,
      scrapId: nil
    )
  }

  static func attachment(id: Int, fileName: String, mimeType: String) -> AraPostAttachment {
    AraPostAttachment(
      id: id,
      createdAt: Date(timeIntervalSince1970: 0),
      file: URL(string: "https://sparcs-newara.s3.amazonaws.com/files/\(fileName)"),
      filename: fileName,
      size: 1_024,
      mimeType: mimeType
    )
  }

  static func page(_ posts: [AraPost], page: Int = 1, pages: Int = 1) -> AraPostPage {
    AraPostPage(pages: pages, items: posts.count, currentPage: page, results: posts)
  }
}
