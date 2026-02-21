//
//  PreviewFeedSettingsViewModel.swift
//  BuddyPreviewSupport
//
//  Created by 하정우 on 2/21/26.
//
import Foundation
import Combine
import BuddyDomain
import UIKit

@Observable
public final class PreviewFeedSettingsViewModel: FeedSettingsViewModelProtocol {
  public var nickname: String = "NICKNAME"
  public var profileImageURL: URL?
  public var profileImageState: ProfileImageChange = .noChange
  public var feedUser: FeedUser?
  public var state: FeedViewState = .loaded
  
  public init() { }
  
  public func fetchUser() async {
    
  }
  
  public func updateNickname(nickname: String) async {
    
  }
  
  public func setProfileImage(image: UIImage) async {
    
  }
  
  public func removeProfileImage() async {
    
  }
  
  public func updateProfile() async {
    
  }
}
