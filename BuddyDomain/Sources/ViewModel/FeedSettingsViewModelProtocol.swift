//
//  FeedSettingsViewModelProtocol.swift
//  BuddyDomain
//
//  Created by 하정우 on 2/21/26.
//

import SwiftUI
import PhotosUI
import UIKit

@MainActor
public protocol FeedSettingsViewModelProtocol: Observable {
  var nickname: String { get set }
  var profileImageURL: URL? { get }
  var profileImageState: FeedProfileImageState { get set }
  var selectedProfileImageItem: PhotosPickerItem? { get set }
  var feedUser: FeedUser? { get }
  var state: FeedViewState { get }
  var isUpdatingProfile: Bool { get }
  
  func fetchUser() async
  func removeProfileImage() async
  func updateProfile() async
}
