//
//  FeedSettingsViewModel.swift
//  BuddyFeature
//
//  Created by 하정우 on 2/20/26.
//

import Foundation
import Combine
import Factory
import BuddyDomain
import UIKit

@Observable
final class FeedSettingsViewModel: FeedSettingsViewModelProtocol {
  // MARK: - Properties
  var nickname: String = ""
  var feedUser: FeedUser?
  var profileImageURL: URL?
  var profileImageState: ProfileImageChange = .noChange
  var state: FeedViewState = .loaded
  
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
  }
  
  func setProfileImage(image: UIImage) async {
    profileImageState = .updated(image)
  }
  
  func removeProfileImage() async {
    profileImageURL = nil
    profileImageState = .removed
  }
  
  func updateProfile() async {
    switch profileImageState {
    case .noChange:
      break
    case .updated(let image):
      try? await feedProfileUseCase?.updateProfileImage(image: image)
    case .removed:
      try? await feedProfileUseCase?.updateProfileImage(image: nil)
    }
    
    if await userUseCase?.feedUser?.nickname != nickname {
      try? await feedProfileUseCase?.updateNickname(nickname: nickname)
    }
    
    await fetchUser()
  }
}
