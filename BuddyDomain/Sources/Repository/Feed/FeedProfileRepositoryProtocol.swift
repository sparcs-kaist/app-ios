//
//  FeedProfileRepositoryProtocol.swift
//  BuddyDomain
//
//  Created by 하정우 on 2/20/26.
//

import Foundation

public protocol FeedProfileRepositoryProtocol: Sendable {
  func updateNickname(nickname: String) async throws
  func setProfileImage(image: PlatformImage) async throws
  func removeProfileImage() async throws
}
