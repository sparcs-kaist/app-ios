//
//  FeedProfileImageState.swift
//  BuddyDomain
//
//  Created by 하정우 on 2/22/26.
//

import UIKit
import Foundation

public enum FeedProfileImageState: Equatable {
  case noChange
  case updated(image: UIImage)
  case removed
  case loading(progress: Progress)
  case error(message: String)
}
