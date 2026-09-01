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
import os

private let logger = Logger(subsystem: "org.sparcs.soap", category: "FeedSettingsViewModel")

@Observable
final class FeedSettingsViewModel: FeedSettingsViewModelProtocol {
  // MARK: - Properties
  var nickname: String = ""
  var feedUser: FeedUser?
  var profileImageURL: URL?
  var profileImageState: FeedProfileImageState = .noChange
  var alertState: AlertState?
  var isAlertPresented: Bool = false
  var state: FeedViewState = .loaded
  var isUpdatingProfile: Bool = false
  
  var selectedProfileImageItem: PhotosPickerItem? = nil {
    didSet {
      guard let selectedProfileImageItem else { return }
      let progress = loadTransferable(from: selectedProfileImageItem)
      profileImageState = .loading(progress: progress)
    }
  }
  
  // MARK: - Dependencies
  @ObservationIgnored @Injected(\.userUseCase) private var userUseCase: UserUseCaseProtocol?
  @ObservationIgnored @Injected(\.feedProfileUseCase) private var feedProfileUseCase: FeedProfileUseCaseProtocol?
  
  // MARK: - Functions
  func fetchUser() async {
    state = .loading
    
    do {
      try await userUseCase?.fetchFeedUser()
      guard let feedUser = await userUseCase?.feedUser else { return }
      
      self.feedUser = feedUser
      nickname = feedUser.nickname
      profileImageURL = feedUser.profileImageURL
      profileImageState = .noChange
      
      state = .loaded
    } catch {
      logger.error("Failed to fetch user: \(error.localizedDescription, privacy: .public)")
      state = .error(message: error.localizedDescription)
    }
  }
  
  func removeProfileImage() async {
    profileImageURL = nil
    profileImageState = .removed
  }
  
  func updateProfile() async -> Bool {
    isUpdatingProfile = true
    defer { isUpdatingProfile = false }
    
    do {
      switch profileImageState {
      case .updated(let image):
        try await feedProfileUseCase?.updateProfileImage(image: image)
      case .removed:
        try await feedProfileUseCase?.updateProfileImage(image: nil)
      default:
        break
      }
      
      if await userUseCase?.feedUser?.nickname != nickname {
        try await feedProfileUseCase?.updateNickname(nickname: nickname)
      }
      
      await fetchUser()
      
      return true
    } catch {
      logger.error("Failed to update profile: \(error.localizedDescription, privacy: .public)")
      alertState = .init(
        title: String(localized: "Failed to update profile.", bundle: .module),
        message: error.localizedDescription
      )
      isAlertPresented = true
      
      return false
    }
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
