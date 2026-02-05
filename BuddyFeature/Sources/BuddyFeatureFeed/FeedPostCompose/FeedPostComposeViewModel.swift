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
import BuddyDomain

@MainActor
protocol FeedPostComposeViewModelProtocol: Observable {
  var feedUser: FeedUser? { get }
  var text: String { get  set }
  var selectedComposeType: FeedPostComposeViewModel.ComposeType { get set }
  var selectedItems: [PhotosPickerItem] { get set }
  var selectedImages: [FeedPostPhotoItem] { get set }

  func fetchFeedUser() async
  func writePost() async throws
  func handleException(_ error: Error)
}

@Observable
class FeedPostComposeViewModel: FeedPostComposeViewModelProtocol {
  enum ComposeType: Int, Hashable, CaseIterable, Identifiable {
    case publicly = 0
    case anonymously = 1
    
    var id: Self { self }
    
    func prettyString(nickname: String?) -> String {
      switch self {
      case .anonymously:
        return String(localized: "Anonymous")
      case .publicly:
        return nickname ?? ""
      }
    }
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
  @ObservationIgnored @Injected(\.userUseCase) private var userUseCase: UserUseCaseProtocol?
  @ObservationIgnored @Injected(
    \.feedImageRepository
  ) private var feedImageRepository: FeedImageRepositoryProtocol?
  @ObservationIgnored @Injected(
    \.feedPostUseCase
  ) private var feedPostUseCase: FeedPostUseCaseProtocol?
  @ObservationIgnored @Injected(
    \.crashlyticsService
  ) private var crashlyticsService: CrashlyticsServiceProtocol?

  // MARK: - Functions
  func fetchFeedUser() async {
    guard let userUseCase else { return }
    
    self.feedUser = await userUseCase.feedUser
  }

  func writePost() async throws {
    guard let feedImageRepository, let feedPostUseCase else { return }

    // Run uploads concurrently
    let uploadedImages: [FeedImage] = try await withThrowingTaskGroup(
      of: (Int, FeedImage).self
    ) { group in
      for (idx, item) in selectedImages.enumerated() {
        group.addTask {
          let image = try await feedImageRepository.uploadPostImage(item: item)
          return (idx, image)
        }
      }

      var ordered = Array<FeedImage?>(repeating: nil, count: selectedImages.count)
      for try await (idx, image) in group {
        ordered[idx] = image
      }
      // All succeeded -> unwrap in order
      return ordered.compactMap { $0 }
    }

    let request = FeedCreatePost(
      content: text,
      isAnonymous: selectedComposeType == .anonymously,
      images: uploadedImages
    )
    try await feedPostUseCase.writePost(request: request)
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
  
  func handleException(_ error: Error) {
    crashlyticsService?.recordException(error: error)
  }
}
