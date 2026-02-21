//
//  FeedSettingsViewModel.swift
//  BuddyFeature
//
//  Created by 하정우 on 2/20/26.
//

import SwiftUI
import PhotosUI
import Factory
import BuddyDomain
import UIKit

@Observable
final class FeedSettingsViewModel: FeedSettingsViewModelProtocol {
  // MARK: - Properties
  var nickname: String = ""
  var feedUser: FeedUser?
  var profileImageURL: URL?
  var profileImageState: FeedProfileImageState = .noChange
  var selectedProfileImageItem: PhotosPickerItem? = nil {
    didSet {
      guard let selectedProfileImageItem else { return }
      let progress = loadTransferable(from: selectedProfileImageItem)
      profileImageState = .loading(progress: progress)
    }
  }
  var state: FeedViewState = .loaded
  var isUpdatingProfile: Bool = false
  
  // MARK: - Dependencies
  @ObservationIgnored @Injected(\.userUseCase) private var userUseCase: UserUseCaseProtocol?
  @ObservationIgnored @Injected(\.feedProfileUseCase) private var feedProfileUseCase: FeedProfileUseCaseProtocol?
  
  // MARK: - Functions
  func fetchUser() async {
    state = .loading
    defer { state = .loaded }
    
    try? await userUseCase?.fetchFeedUser()
    guard let feedUser = await userUseCase?.feedUser else { return }
    
    self.feedUser = feedUser
    nickname = feedUser.nickname
    profileImageURL = feedUser.profileImageURL
    profileImageState = .noChange
  }
  
  func removeProfileImage() async {
    profileImageURL = nil
    profileImageState = .removed
  }
  
  func updateProfile() async {
    isUpdatingProfile = true
    defer { isUpdatingProfile = false }
    
    switch profileImageState {
    case .updated(let image):
      try? await feedProfileUseCase?.updateProfileImage(image: image)
    case .removed:
      try? await feedProfileUseCase?.updateProfileImage(image: nil)
    default:
      break
    }
    
    if await userUseCase?.feedUser?.nickname != nickname {
      try? await feedProfileUseCase?.updateNickname(nickname: nickname)
    }
    
    await fetchUser()
  }
  
  private func loadTransferable(from selectedImage: PhotosPickerItem) -> Progress {
    return selectedImage.loadTransferable(type: Data.self) { result in
      Task { @MainActor in
        guard selectedImage == self.selectedProfileImageItem else { return }
        
        switch result {
        case .success(let imageData?):
          if let uiImage = UIImage(data: imageData) {
            self.profileImageState = .updated(image: uiImage)
          }
        case .success(nil):
          self.profileImageState = .noChange
        case .failure(let error):
          self.profileImageState = .error(message: error.localizedDescription)
        }
      }
    }
  }
}
