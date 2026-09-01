import Foundation
import Testing
@testable import BuddyFeedCore

@Test func changingVoteUpdatesCountsAndRequest() {
  let original = FeedPreview.page().items[1]
  let transition = original.togglingVote(.down)

  #expect(transition.post.myVote == .down)
  #expect(transition.post.upvotes == original.upvotes - 1)
  #expect(transition.post.downvotes == original.downvotes + 1)
  #expect(transition.request == .set(.down))
}

@Test func togglingExistingVoteDeletesIt() {
  let original = FeedPreview.page().items[1]
  let transition = original.togglingVote(.up)

  #expect(transition.post.myVote == nil)
  #expect(transition.post.upvotes == original.upvotes - 1)
  #expect(transition.request == .delete)
}

@Test func feedPayloadDecodesSnakeCaseAPIResponse() throws {
  let json = #"{"items":[{"id":"1","content":"Hello","is_anonymous":false,"is_kaist_ip":true,"author_name":"Buddy","nickname":"Buddy","profile_image_url":null,"created_at":"2026-09-01T09:00:00.000Z","comment_count":2,"upvotes":5,"downvotes":1,"my_vote":"UP","is_author":false,"images":[]}],"next_cursor":"next","has_next":true}"#
  let page = try FeedPageDecoder.decode(json)

  #expect(page.items.first?.authorName == "Buddy")
  #expect(page.items.first?.score == 4)
  #expect(page.nextCursor == "next")
  #expect(page.hasNext)
}

@Test func timelineAppendsWithoutDuplicates() {
  let page = FeedPreview.page()
  var timeline = FeedTimeline()
  timeline.replace(with: page)
  timeline.append(page)

  #expect(timeline.posts.count == page.items.count)
}

@Test func sharedViewModelOwnsLoadingAndPaginationState() {
  let firstPage = FeedPostPage(
    items: [FeedPreview.page().items[0]],
    nextCursor: "next-page",
    hasNext: true
  )
  var viewModel = FeedViewModelCore()

  let initial = viewModel.beginInitialLoad()
  #expect(initial == FeedPageRequest(intent: .initial, cursor: nil, limit: 20))
  viewModel.receive(firstPage, for: .initial)
  #expect(viewModel.phase == .loaded)

  let next = viewModel.beginNextPage()
  #expect(next == FeedPageRequest(intent: .next, cursor: "next-page", limit: 20))
  #expect(viewModel.isLoadingMore)
  viewModel.receive(FeedPreview.page(), for: .next)
  #expect(viewModel.posts.count == FeedPreview.page().items.count)
  #expect(!viewModel.isLoadingMore)
}

@Test func sharedViewModelRollsBackFailedVote() {
  var viewModel = FeedViewModelCore()
  viewModel.loadPreview()
  let original = viewModel.posts[0]

  let command = viewModel.beginVote(postID: original.id, type: .up)
  #expect(command?.method == "POST")
  #expect(viewModel.posts[0].score == original.score + 1)
  #expect(viewModel.votingPostIDs.contains(original.id))

  viewModel.failVote(postID: original.id, message: "Try again")
  #expect(viewModel.posts[0] == original)
  #expect(viewModel.notice == "Try again")
  #expect(!viewModel.votingPostIDs.contains(original.id))
}
