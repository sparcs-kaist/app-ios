import Testing
import BuddyDomain
@testable import BuddyDataCore

@Suite("Lecture review batching")
struct LectureReviewBatchingTests {
  private func review(
    id: Int,
    content: String,
    like: Int = 0,
    year: Int = 2025,
    isDeleted: Bool = false
  ) -> LectureReview {
    LectureReview(
      id: id,
      courseID: 1,
      lectureID: 1,
      courseName: "Data Structures",
      professors: [],
      year: year,
      semester: .spring,
      content: content,
      like: like,
      grade: "A",
      load: "B",
      speech: "C",
      isDeleted: isDeleted,
      likedByUser: false
    )
  }

  @Test func linesSkipDeletedAndEmptyReviews() {
    let lines = LectureReviewBatching.lines(for: [
      review(id: 1, content: "Good"),
      review(id: 2, content: "Deleted", isDeleted: true),
      review(id: 3, content: "  \n "),
    ])
    #expect(lines == ["- [Grade A, Load B, Speech C] Good"])
  }

  @Test func linesPutMostLikedThenNewestFirst() {
    let lines = LectureReviewBatching.lines(for: [
      review(id: 1, content: "old", like: 1, year: 2020),
      review(id: 2, content: "popular", like: 5, year: 2019),
      review(id: 3, content: "new", like: 1, year: 2025),
    ])
    #expect(lines.map { $0.split(separator: "] ").last.map(String.init) } == ["popular", "new", "old"])
  }

  @Test func linesKeepEachReviewOnOneShortLine() throws {
    let long = String(repeating: "가", count: LectureReviewBatching.maximumReviewLength + 50)
    let lines = LectureReviewBatching.lines(for: [
      review(id: 1, content: "first\n\nsecond   third"),
      review(id: 2, content: long),
    ])
    #expect(lines[0].hasSuffix("] first second third"))
    let text = try #require(lines[1].split(separator: "] ").last)
    #expect(text.count == LectureReviewBatching.maximumReviewLength + 1)
    #expect(text.hasSuffix("…"))
  }

  @Test func batchesPackLinesWithinTheBudget() async {
    let batches = await LectureReviewBatching.batches(of: ["a", "b", "c", "d", "e"], budget: 2) { _ in 1 }
    #expect(batches == [["a", "b"], ["c", "d"], ["e"]])
  }

  @Test func batchesGiveAnOversizedLineItsOwnBatch() async {
    let batches = await LectureReviewBatching.batches(of: ["short", "huge", "short"], budget: 5) { line in
      line == "huge" ? 10 : 2
    }
    #expect(batches == [["short"], ["huge"], ["short"]])
  }

  @Test func batchesStopAtTheMaximum() async {
    let lines = (0..<20).map(String.init)
    let batches = await LectureReviewBatching.batches(of: lines, budget: 1) { _ in 1 }
    #expect(batches.count == LectureReviewBatching.maximumBatches)
    #expect(batches.flatMap(\.self) == Array(lines.prefix(LectureReviewBatching.maximumBatches)))
  }

  @Test func estimatedTokensCountHangulHigherThanLatin() {
    #expect(LectureReviewBatching.estimatedTokens("좋아요") == 3)
    #expect(LectureReviewBatching.estimatedTokens("good class") == 4)
  }
}
