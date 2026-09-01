//
//  FeedImageRepositoryProtocol.swift
//  BuddyDomain
//
//  Created by Soongyu Kwon on 05/10/2025.
//

import Foundation

public protocol FeedImageRepositoryProtocol: Sendable {
  func uploadPostImage(item: FeedPostPhotoItem) async throws -> FeedImage
}
