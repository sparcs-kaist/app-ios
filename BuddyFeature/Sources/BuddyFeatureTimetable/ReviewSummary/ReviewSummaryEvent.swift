//
//  ReviewSummaryEvent.swift
//  BuddyFeature
//
//  Created by Soongyu Kwon on 12/10/2026.
//

import BuddyDomain
import Foundation

enum ReviewSummaryEvent: Event {
  case requested(source: String)
  case finished(source: String)
  case failed(source: String, reason: SummarisationError)

  var source: String {
    switch self {
    case let .requested(source), let .finished(source), let .failed(source, _):
      source
    }
  }

  var name: String {
    switch self {
    case .requested:
      "review_summary_requested"
    case .finished:
      "review_summary_finished"
    case .failed:
      "review_summary_failed"
    }
  }

  var parameters: [String: Any] {
    switch self {
    case .requested, .finished:
      ["source": source]
    case let .failed(_, reason):
      ["source": source, "reason": String(describing: reason)]
    }
  }
}
