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

@MainActor
protocol PostComposeViewModelProtocol: Observable {
  var board: AraBoard { get }

  var selectedTopic: AraBoardTopic? { get set }
  var title: String { get set }
  var content: String { get set }
  var selectedItems: [PhotosPickerItem] { get set }
  var selectedImages: [UIImage] { get }

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
  var selectedImages: [UIImage] = []

  var writeAsAnonymous: Bool = true
  var isNSFW: Bool = false
  var isPolitical: Bool = false

  // MARK: - Dependencies
  @ObservationIgnored @Injected(
    \.araBoardRepository
  ) private var araBoardRepository: AraBoardRepositoryProtocol?

  init(board: AraBoard) {
    self.board = board
  }

  func writePost() async throws {
    guard let araBoardRepository else { return }
    
    var attachments: [AraAttachment] = []
    for image in selectedImages {
      let attachment: AraAttachment = try await araBoardRepository.uploadImage(image: image)

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

    try await araBoardRepository.writePost(request: request)
  }

  private func loadSelectedImages() async {
    var images: [UIImage] = []

    for item in selectedItems {
      if let data = try? await item.loadTransferable(type: Data.self),
         let image = UIImage(data: data) {
        images.append(image)
      }
    }

    selectedImages = images
  }
}
