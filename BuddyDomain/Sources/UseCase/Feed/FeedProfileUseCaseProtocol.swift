//
//  FeedProfileUseCaseProtocol.swift
//  BuddyDomain
//
//  Created by 하정우 on 2/20/26.
//

import Foundation

public protocol FeedProfileUseCaseProtocol: Sendable {
  func updateNickname(nickname: String) async throws
  func updateProfileImage(image: PlatformImage?) async throws
}
