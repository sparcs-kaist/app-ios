//
//  ReviewDigestEvent.swift
//  BuddyFeature
//
//  Created by Soongyu Kwon on 11/10/2026.
//

import BuddyDomain
import Foundation

enum ReviewDigestEvent: Event {
  case requested(source: String, reviewCount: Int)
  case finished(source: String)
  case failed(source: String, reason: LectureReviewDigestError)

  var source: String {
    switch self {
    case let .requested(source, _), let .finished(source), let .failed(source, _):
      source
    }
  }

  var name: String {
    switch self {
    case .requested:
      "review_digest_requested"
    case .finished:
      "review_digest_finished"
    case .failed:
      "review_digest_failed"
    }
  }

  var parameters: [String: Any] {
    switch self {
    case let .requested(_, reviewCount):
      ["source": source, "review_count": reviewCount]
    case .finished:
      ["source": source]
    case let .failed(_, reason):
      ["source": source, "reason": String(describing: reason)]
    }
  }
}
