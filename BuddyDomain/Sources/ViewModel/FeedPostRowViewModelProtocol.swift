//
//  FeedPostRowViewModelProtocol.swift
//  BuddyDomain
//
//  Created by Soongyu Kwon on 07/02/2026.
//

import SwiftUI

@MainActor
public protocol FeedPostRowViewModelProtocol: Observable {
  var alertState: AlertState? { get }
  var isAlertPresented: Bool { get set }

  func upvote(post: Binding<FeedPost>) async
  func downvote(post: Binding<FeedPost>) async
  func reportPost(postID: String, reason: FeedReportType) async
}
