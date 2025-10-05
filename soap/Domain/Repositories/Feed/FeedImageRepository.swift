//
//  FeedImageRepository.swift
//  soap
//
//  Created by Soongyu Kwon on 21/08/2025.
//

import Foundation
import UIKit
import BuddyDomain

@preconcurrency
import Moya

protocol FeedImageRepositoryProtocol: Sendable {
  func uploadPostImage(item: FeedPostPhotoItem) async throws -> FeedImage
}

final class FeedImageRepository: FeedImageRepositoryProtocol {
  private let provider: MoyaProvider<FeedImageTarget>

  init(provider: MoyaProvider<FeedImageTarget>) {
    self.provider = provider
  }

  func uploadPostImage(item: FeedPostPhotoItem) async throws -> FeedImage {
    guard let imageData = item.image.compressForUpload(maxSizeMB: 10.0) else {
      throw NSError(domain: "FeedImageRepository", code: 1)
    }

    let response = try await provider.request(
      .uploadPostImage(imageData: imageData, description: item.description, spoiler: item.spoiler)
    )
    _ = try response.filterSuccessfulStatusCodes()

    let imageDTO: FeedImageDTO = try response.map(FeedImageDTO.self)
    guard let image = imageDTO.toModel() else {
      throw NSError(domain: "FeedImageRepository", code: 2)
    }

    return image
  }
}
