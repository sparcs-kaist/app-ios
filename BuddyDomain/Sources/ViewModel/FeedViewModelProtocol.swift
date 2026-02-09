//
//  FeedViewModelProtocol.swift
//  BuddyDomain
//
//  Created by Soongyu Kwon on 07/02/2026.
//

import SwiftUI

@MainActor
public protocol FeedViewModelProtocol: Observable {
  var state: FeedViewState { get }
  var posts: [FeedPost] { get set }
  var alertState: AlertState? { get }
  var isAlertPresented: Bool { get set }

  func fetchInitialData() async
  func deletePost(postID: String) async

  func openSettingsTapped()
  func refreshFeed() async
  func writeFeedButtonTapped()
}
