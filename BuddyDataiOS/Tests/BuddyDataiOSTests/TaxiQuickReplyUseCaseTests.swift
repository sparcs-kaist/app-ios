import Testing
import Foundation
import BuddyDomain
@testable import BuddyDataiOS

@Suite("Taxi quick reply")
struct TaxiQuickReplyUseCaseTests {
  @Test func sendsTheReplyAndMarksTheRoomRead() async throws {
    let chats = Chats()
    try await TaxiQuickReplyUseCase(taxiChatRepository: chats).reply("  on my way ", roomID: "ride")

    #expect(chats.sent == ["on my way"])
    #expect(chats.read == ["ride"])
  }

  @Test func aSendThatFailsSaysSo() async {
    let chats = Chats()
    chats.sendError = URLError(.notConnectedToInternet)

    await #expect(throws: URLError.self) {
      try await TaxiQuickReplyUseCase(taxiChatRepository: chats).reply("hi", roomID: "ride")
    }
    #expect(chats.read.isEmpty)
  }

  @Test func failingToMarkTheRoomReadStillSendsTheReply() async throws {
    let chats = Chats()
    chats.readError = URLError(.timedOut)

    try await TaxiQuickReplyUseCase(taxiChatRepository: chats).reply("hi", roomID: "ride")
    #expect(chats.sent == ["hi"])
  }

  @Test func aSendThatHangsGivesUp() async {
    let chats = Chats()
    chats.hangsSending = true
    let useCase = TaxiQuickReplyUseCase(taxiChatRepository: chats, sendTimeout: .milliseconds(100))

    let start = ContinuousClock.now
    await #expect(throws: TaxiQuickReplyUseCase.TimedOut.self) { try await useCase.reply("hi", roomID: "ride") }
    #expect(ContinuousClock.now - start < .seconds(2))
  }

  @Test func markingReadThatHangsDoesntHoldUpTheReply() async throws {
    let chats = Chats()
    chats.hangsReading = true
    let useCase = TaxiQuickReplyUseCase(taxiChatRepository: chats, readTimeout: .milliseconds(100))

    let start = ContinuousClock.now
    try await useCase.reply("hi", roomID: "ride")
    #expect(chats.sent == ["hi"])
    #expect(ContinuousClock.now - start < .seconds(2))
  }

  final class Chats: TaxiChatRepositoryProtocol, @unchecked Sendable {
    /// Like a request that never comes back, and ignores being cancelled.
    var hangsSending = false
    var hangsReading = false
    var sent: [String] = []
    var read: [String] = []
    var sendError: Error?
    var readError: Error?

    func sendChat(_ request: TaxiChatRequest) async throws {
      if hangsSending { await withCheckedContinuation { (_: CheckedContinuation<Void, Never>) in } }
      if let sendError { throw sendError }
      sent.append(request.content ?? "")
    }

    func readChats(roomID: String) async throws {
      if hangsReading { await withCheckedContinuation { (_: CheckedContinuation<Void, Never>) in } }
      if let readError { throw readError }
      read.append(roomID)
    }

    func fetchChats(roomID: String) async throws {}
    func fetchChats(roomID: String, before: Date) async throws {}
    func fetchChats(roomID: String, after: Date) async throws {}
    func getPresignedURL(roomID: String) async throws -> TaxiChatPresignedURL { throw CancellationError() }
    func uploadImage(presignedURL: TaxiChatPresignedURL, imageData: Data) async throws {}
    func notifyImageUploadComplete(id: String) async throws {}
  }
}
