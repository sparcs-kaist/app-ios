//
//  PostContentTests.swift
//  BuddyFeature
//
//  Created by Soongyu Kwon on 24/10/2026.
//

import Foundation
import Testing
@testable import BuddyFeaturePost
@testable import BuddyDomain

extension PostFeatureTests {
  @Suite("Post content")
  struct PostContentTests {
    @Test func listsPhotosAttachedButNotPlacedInTheText() {
      let post = AraFixtures.post(
        id: 1,
        content: #"<p>Room</p><img src="https://sparcs-newara.s3.amazonaws.com/files/inline.jpg">"#,
        attachments: [
          AraFixtures.attachment(id: 1, fileName: "inline.jpg", mimeType: "image/jpeg"),
          AraFixtures.attachment(id: 2, fileName: "kitchen.jpg", mimeType: "image/jpeg"),
          AraFixtures.attachment(id: 3, fileName: "contract.pdf", mimeType: "application/pdf"),
        ]
      )

      #expect(post.attachedImageURLs.map(\.lastPathComponent) == ["kitchen.jpg"])
    }

    @Test func matchesPercentEncodedFileNames() {
      let post = AraFixtures.post(
        id: 1,
        content: #"{"type":"doc","content":[{"type":"image","attrs":{"src":"https://sparcs-newara.s3.amazonaws.com/files/%EB%B0%A9.jpg"}}]}"#,
        attachments: [AraFixtures.attachment(id: 1, fileName: "%EB%B0%A9.jpg", mimeType: "image/jpeg")]
      )

      #expect(post.attachedImageURLs.isEmpty)
    }

    @Test(arguments: [
      (BoardHighlight.trending, true, PostListType.trending),
      (.latest(boardIDs: [2, 3]), false, .latest(boardIDs: [2, 3])),
    ])
    func highlightsLoadTheirOwnList(highlight: BoardHighlight, isRanked: Bool, listType: PostListType) {
      #expect(highlight.isRanked == isRanked)
      #expect(highlight.listType == listType)
    }
  }
}
