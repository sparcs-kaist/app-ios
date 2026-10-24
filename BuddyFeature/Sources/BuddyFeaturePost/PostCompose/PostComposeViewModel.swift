//
//  PostComposeViewModel.swift
//  soap
//
//  Created by Soongyu Kwon on 10/08/2025.
//

import SwiftUI
import Observation
import Factory
import BuddyDomain
import TiptapKit
import TiptapEditor

@MainActor
protocol PostComposeViewModelProtocol: Observable {
  var board: AraBoard { get }

  var selectedTopic: AraBoardTopic? { get set }
  var title: String { get set }
  /// The body, written in a Notes-like editor with photos placed in the text.
  var editor: TiptapEditorController { get }

  var writeAsAnonymous: Bool { get set }
  var isNSFW: Bool { get set }
  var isPolitical: Bool { get set }

  func writePost() async throws
}

@Observable
class PostComposeViewModel: PostComposeViewModelProtocol {
  // MARK: - Properties
  var board: AraBoard

  var selectedTopic: AraBoardTopic? = nil
  var title: String = ""
  let editor = TiptapEditorController()

  var writeAsAnonymous: Bool = true
  var isNSFW: Bool = false
  var isPolitical: Bool = false

  // MARK: - Dependencies
  @ObservationIgnored @Injected(
    \.araBoardUseCase
  ) private var araBoardUseCase: AraBoardUseCaseProtocol?
  @ObservationIgnored @Injected(
    \.analyticsService
  ) private var analyticsService: AnalyticsServiceProtocol?

  init(board: AraBoard) {
    self.board = board
  }

  func writePost() async throws {
    guard let araBoardUseCase else { return }

    // Upload every photo first, then write each one where it sits in the text.
    var uploads: [UUID: AraAttachment] = [:]
    var attachments: [AraAttachment] = []
    for image in editor.imageAttachments {
      let attachment: AraAttachment = try await araBoardUseCase.uploadImage(image: image.originalImage)
      uploads[image.id] = attachment
      attachments.append(attachment)
    }

    let uploaded = uploads
    let converter = TiptapAttributedStringConverter { attachment in
      guard let image = attachment as? TiptapImageAttachment,
            let upload = uploaded[image.id],
            let file = upload.file else { return nil }
      // The same attributes the Ara web editor writes; 500 is its default ("mid") width.
      return TiptapNode(type: .attachmentImage, attrs: [
        "src": .string(file.absoluteString),
        "width": .number(500),
        "data-attachment": .string(String(upload.id)),
      ])
    }
    let content = converter.document(from: editor.attributedText).jsonString()

    let request = AraCreatePost(
      title: title,
      content: content,
      attachments: attachments,
      topic: selectedTopic,
      isNSFW: isNSFW,
      isPolitical: isPolitical,
      nicknameType: writeAsAnonymous ? .anonymous : .regular,
      board: board
    )

    try await araBoardUseCase.writePost(request: request)
    analyticsService?.logEvent(PostComposeViewEvent.postSubmitted)
  }
}
