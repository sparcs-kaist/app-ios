//
//  FeedProfileRepository.swift
//  BuddyDataiOS
//
//  Created by 하정우 on 2/20/26.
//

import Foundation
import BuddyDomain
import UIKit

@preconcurrency
import Moya

public final class FeedProfileRepository: FeedProfileRepositoryProtocol {
  private let provider: MoyaProvider<FeedProfileTarget>
  
  public init(provider: MoyaProvider<FeedProfileTarget>) {
    self.provider = provider
  }
  
  public func updateNickname(nickname: String) async throws {
    _ = try await provider.request(.updateNickname(nickname: nickname))
  }
  
  public func setProfileImage(image: UIImage) async throws {
    guard let imageData = image.compressForUpload(maxSizeMB: 1024) else {
      throw NSError(domain: "FeedProfileRepository", code: 1)
    }
    
    _ = try await provider.request(.setProfileImage(image: imageData))
  }
  
  public func removeProfileImage() async throws {
    _ = try await provider.request(.removeProfileImage)
  }
}
