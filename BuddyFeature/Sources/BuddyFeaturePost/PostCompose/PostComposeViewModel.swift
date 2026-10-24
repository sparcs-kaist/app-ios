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
import Nuke

@MainActor
protocol PostComposeViewModelProtocol: Observable {
  var board: AraBoard { get }
  /// The post being edited, or `nil` when writing a new one.
  var editingPost: AraPost? { get }
  /// Whether an edited post's content is still loading into the editor.
  var isLoadingContent: Bool { get }

  var selectedTopic: AraBoardTopic? { get set }
  var title: String { get set }
  /// The body, written in a Notes-like editor with photos placed in the text.
  var editor: TiptapEditorController { get }

  var writeAsAnonymous: Bool { get set }
  var isNSFW: Bool { get set }
  var isPolitical: Bool { get set }

  /// Loads the edited post's body, photos included, into the editor.
  func loadContentForEditing() async
  /// Writes the new post, or saves the edited one.
  func submit() async throws
}

@Observable
class PostComposeViewModel: PostComposeViewModelProtocol {
  // MARK: - Properties
  var board: AraBoard
  let editingPost: AraPost?
  private(set) var isLoadingContent = false

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
    self.editingPost = nil
  }

  /// Edits `post`, which must belong to a board.
  init(editing post: AraPost, board: AraBoard) {
    self.board = board
    self.editingPost = post
    self.selectedTopic = post.topic
    self.title = post.title ?? ""
    self.isNSFW = post.isNSFW
    self.isPolitical = post.isPolitical
    self.writeAsAnonymous = post.author.username == "anonymous"
  }

  // MARK: - Loading

  func loadContentForEditing() async {
    guard let post = editingPost,
          let document = PostEditableContent.document(from: post.content ?? "") else { return }
    isLoadingContent = true
    defer { isLoadingContent = false }

    // Existing photos are shown as they are; they're already uploaded and stay that way.
    var images: [URL: UIImage] = [:]
    for url in Self.imageURLs(in: document.content) where images[url] == nil {
      images[url] = try? await ImagePipeline.shared.image(for: url)
    }
    let text = TiptapAttributedStringConverter.attributedString(from: document) { node in
      guard let url = Self.imageURL(of: node) else { return nil }
      return TiptapImageAttachment(image: images[url] ?? Self.missingImage, existingNode: node)
    }
    editor.setAttributedText(text)
  }

  private static func imageURL(of node: TiptapNode) -> URL? {
    guard let src = node[attribute: "src"]?.stringValue else { return nil }
    return URL(string: src, relativeTo: Constants.araPostURL)?.absoluteURL
  }

  private static func imageURLs(in nodes: [TiptapNode]) -> [URL] {
    nodes.flatMap { node -> [URL] in
      if node.type == .attachmentImage || node.type == .image {
        return imageURL(of: node).map { [$0] } ?? []
      }
      return imageURLs(in: node.content)
    }
  }

  /// Stands in for a photo that couldn't be downloaded, which is still kept in the post.
  private static let missingImage: UIImage = {
    let size = CGSize(width: 400, height: 300)
    return UIGraphicsImageRenderer(size: size).image { context in
      UIColor.secondarySystemFill.setFill()
      context.fill(CGRect(origin: .zero, size: size))
      let symbol = UIImage(systemName: "photo", withConfiguration: UIImage.SymbolConfiguration(pointSize: 48))?
        .withTintColor(.secondaryLabel, renderingMode: .alwaysOriginal)
      symbol?.draw(at: CGPoint(x: (size.width - (symbol?.size.width ?? 0)) / 2, y: (size.height - (symbol?.size.height ?? 0)) / 2))
    }
  }()

  // MARK: - Submitting

  func submit() async throws {
    guard let araBoardUseCase else { return }

    // Upload every new photo first, then write each one where it sits in the text.
    var uploads: [UUID: AraAttachment] = [:]
    for image in editor.imageAttachments where image.existingNode == nil {
      uploads[image.id] = try await araBoardUseCase.uploadImage(image: image.originalImage)
    }

    let uploaded = uploads
    let converter = TiptapAttributedStringConverter { attachment in
      guard let image = attachment as? TiptapImageAttachment else { return nil }
      if let existing = image.existingNode {
        return existing
      }
      guard let upload = uploaded[image.id], let file = upload.file else { return nil }
      // The same attributes the Ara web editor writes; 500 is its default ("mid") width.
      return TiptapNode(type: .attachmentImage, attrs: [
        "src": .string(file.absoluteString),
        "width": .number(500),
        "data-attachment": .string(String(upload.id)),
      ])
    }
    let document = converter.document(from: editor.attributedText)

    if let post = editingPost {
      let request = AraUpdatePost(
        title: title,
        content: document.jsonString(),
        attachmentIDs: Self.attachmentIDs(keptBy: document, from: post),
        isNSFW: isNSFW,
        isPolitical: isPolitical
      )
      try await araBoardUseCase.updatePost(postID: post.id, request: request)
      analyticsService?.logEvent(PostComposeViewEvent.postEdited)
    } else {
      let request = AraCreatePost(
        title: title,
        content: document.jsonString(),
        attachments: editor.imageAttachments.compactMap { uploaded[$0.id] },
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

  /// The attachments an edited post keeps: files that aren't shown in the text, and every
  /// photo still in it. A photo removed from the text is dropped from the post.
  static func attachmentIDs(keptBy document: TiptapDocument, from post: AraPost) -> [Int] {
    let original = post.attachments ?? []
    var ids = original.filter { !$0.mimeType.hasPrefix("image/") }.map(\.id)

    func collect(_ nodes: [TiptapNode]) {
      for node in nodes {
        if node.type == .attachmentImage || node.type == .image {
          // Older posts may lack `data-attachment`; their file URL still identifies them.
          let id = node[attribute: "data-attachment"]?.intValue
            ?? original.first { $0.file?.absoluteString == node[attribute: "src"]?.stringValue }?.id
          if let id, !ids.contains(id) {
            ids.append(id)
          }
        }
        collect(node.content)
      }
    }
    collect(document.content)
    return ids
  }
}
