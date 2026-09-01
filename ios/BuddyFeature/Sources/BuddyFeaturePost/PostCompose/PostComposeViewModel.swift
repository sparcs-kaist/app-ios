//
//  PostComposeViewModel.swift
//  soap
//
//  Created by Soongyu Kwon on 10/08/2025.
//

import SwiftUI
import Observation
import Factory
import PhotosUI
import BuddyDomain

/// A selected image paired with a stable identity, so `ForEach` can track each
/// row across body evaluations without using the `UIImage` itself as the id.
struct PostComposeImage: Identifiable, Hashable {
  let id: String
  let image: UIImage
}

@MainActor
protocol PostComposeViewModelProtocol: Observable {
  var board: AraBoard { get }

  var selectedTopic: AraBoardTopic? { get set }
  var title: String { get set }
  var content: String { get set }
  var selectedItems: [PhotosPickerItem] { get set }
  var selectedImages: [PostComposeImage] { get }

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
  var content: String = ""
  var selectedItems: [PhotosPickerItem] = [] {
    didSet {
      Task {
        await loadSelectedImages()
      }
    }
  }
  var selectedImages: [PostComposeImage] = []

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

    var attachments: [AraAttachment] = []
    for selected in selectedImages {
      let attachment: AraAttachment = try await araBoardUseCase.uploadImage(image: selected.image)

      attachments.append(attachment)
    }

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

  private func loadSelectedImages() async {
    var images: [PostComposeImage] = []

    for item in selectedItems {
      if let data = try? await item.loadTransferable(type: Data.self),
         let image = UIImage(data: data) {
        images.append(PostComposeImage(id: UUID().uuidString, image: image))
      }
    }

    selectedImages = images
  }
}
