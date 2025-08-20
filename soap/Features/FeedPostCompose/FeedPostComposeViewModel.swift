//
//  FeedPostComposeViewModel.swift
//  soap
//
//  Created by Soongyu Kwon on 20/08/2025.
//

import SwiftUI
import Observation
import Factory
import PhotosUI

@MainActor
protocol FeedPostComposeViewModelProtocol: Observable {
  var feedUser: FeedUser? { get }
  var text: String { get  set }
  var selectedComposeType: FeedPostComposeViewModel.ComposeType { get set }
  var selectedItems: [PhotosPickerItem] { get set }
  var selectedImages: [FeedPostPhotoItem] { get }

  func fetchFeedUser() async
}

struct FeedPostPhotoItem: Identifiable, Hashable {
  let id: String
  let image: UIImage
  let spoiler: Bool
  let description: String
}

@Observable
class FeedPostComposeViewModel: FeedPostComposeViewModelProtocol {
  enum ComposeType: Int, Hashable {
    case publicly = 0
    case anonymously = 1
  }

  // MARK: - Properties
  var feedUser: FeedUser?
  var text: String = ""
  var selectedComposeType: ComposeType = .anonymously
  var selectedItems: [PhotosPickerItem] = [] {
    didSet {
      Task {
        await self.loadImagesAndReconcile()
      }
    }
  }
  var selectedImages: [FeedPostPhotoItem] = []

  // MARK: - Dependencies
  @ObservationIgnored @Injected(\.userUseCase) private var userUseCase: UserUseCaseProtocol

  // MARK: - Functions
  func fetchFeedUser() async {
    self.feedUser = await userUseCase.feedUser
  }

  private func loadImagesAndReconcile() async {
    var loaded: [FeedPostPhotoItem] = []
    loaded.reserveCapacity(selectedItems.count)

    await withTaskGroup(of: (index: Int, item: FeedPostPhotoItem?)?.self) { group in
      for (idx, pickerItem) in selectedItems.enumerated() {
        group.addTask {
          guard let id = pickerItem.itemIdentifier else {
            if let img = await self.loadUIImage(from: pickerItem) {
              return (
                idx,
                FeedPostPhotoItem(id: UUID().uuidString, image: img, spoiler: false, description: "")
              )
            }
            return (idx, nil)
          }

          if let img = await self.loadUIImage(from: pickerItem) {
            return (idx, FeedPostPhotoItem(id: id, image: img, spoiler: false, description: ""))
          }
          return (idx, nil)
        }
      }

      var temp = Array<FeedPostPhotoItem?>(repeating: nil, count: selectedItems.count)
      for await result in group {
        if let (idx, item) = result {
          temp[idx] = item
        }
      }
      loaded = temp.compactMap { $0 }
    }

    self.selectedImages = reconcile(new: loaded, current: self.selectedImages)
  }

  private func reconcile(new: [FeedPostPhotoItem], current: [FeedPostPhotoItem]) -> [FeedPostPhotoItem] {
    let byId = Dictionary(uniqueKeysWithValues: current.map { ($0.id, $0) })
    return new.map { fresh in
      if let old = byId[fresh.id] {
        return FeedPostPhotoItem(
          id: fresh.id,
          image: fresh.image,
          spoiler: old.spoiler,
          description: old.description
        )
      } else {
        return fresh
      }
    }
  }

  private func loadUIImage(from item: PhotosPickerItem) async -> UIImage? {
    if let data = try? await item.loadTransferable(type: Data.self),
       let uiImage = UIImage(data: data) {
      return uiImage
    }

    return nil
  }
}
