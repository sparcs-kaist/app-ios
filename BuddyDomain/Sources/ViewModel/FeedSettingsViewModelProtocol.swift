//
//  FeedSettingsViewModelProtocol.swift
//  BuddyDomain
//
//  Created by 하정우 on 2/21/26.
//
import Foundation
import Combine
import UIKit

public enum ProfileImageChange: Equatable {
  case noChange
  case updated(UIImage)
  case removed
}

@MainActor
public protocol FeedSettingsViewModelProtocol: Observable {
  var nickname: String { get set }
  var profileImageURL: URL? { get }
  var profileImageState: ProfileImageChange { get set }
  var feedUser: FeedUser? { get }
  var state: FeedViewState { get }
  
  func fetchUser() async
  func setProfileImage(image: UIImage) async
  func removeProfileImage() async
  func updateProfile() async
}
