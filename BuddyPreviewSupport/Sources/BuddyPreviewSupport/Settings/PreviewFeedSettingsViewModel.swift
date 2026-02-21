//
//  PreviewFeedSettingsViewModel.swift
//  BuddyPreviewSupport
//
//  Created by 하정우 on 2/21/26.
//
import SwiftUI
import PhotosUI
import Combine
import BuddyDomain
import UIKit

@Observable
public final class PreviewFeedSettingsViewModel: FeedSettingsViewModelProtocol {
  public var nickname: String = "NICKNAME"
  public var profileImageURL: URL?
  public var profileImageState: FeedProfileImageState = .noChange
  public var selectedProfileImageItem: PhotosPickerItem?
  public var feedUser: FeedUser?
  public var state: FeedViewState = .loaded
  public var isUpdatingProfile: Bool = false
  
  public init() { }
  
  public func fetchUser() async {
    
  }
  
  public func removeProfileImage() async {
    
  }
  
  public func updateProfile() async {
    
  }
}
