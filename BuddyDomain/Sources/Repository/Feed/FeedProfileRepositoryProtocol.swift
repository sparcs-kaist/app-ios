//
//  FeedProfileRepositoryProtocol.swift
//  BuddyDomain
//
//  Created by 하정우 on 2/20/26.
//

import Foundation
import UIKit

public protocol FeedProfileRepositoryProtocol: Sendable {
  func updateNickname(nickname: String) async throws
  func setProfileImage(image: UIImage) async throws
  func removeProfileImage() async throws
}
