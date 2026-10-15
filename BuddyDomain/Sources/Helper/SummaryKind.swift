//
//  SummaryKind.swift
//  BuddyDomain
//
//  Created by Soongyu Kwon on 12/10/2026.
//

import Foundation

/// What is being summarised, which decides what the summary keeps: a review is
/// read to choose a lecture, a post to decide whether it's worth opening.
public enum SummaryKind: Sendable {
  /// One student's review of a lecture, as plain text.
  case lectureReview
  /// A post on a community board such as Ara, as plain text.
  case post
}
