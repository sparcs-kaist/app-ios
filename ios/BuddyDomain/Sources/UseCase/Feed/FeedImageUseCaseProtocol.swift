//
//  FeedImageUseCaseProtocol.swift
//  BuddyDomain
//
//  Created by Soongyu Kwon on 05/02/2026.
//

import Foundation

public protocol FeedImageUseCaseProtocol: Sendable {
  func uploadPostImage(item: FeedPostPhotoItem) async throws -> FeedImage
}
