//
//  LectureReviewDigest.swift
//  BuddyDomain
//
//  Created by Soongyu Kwon on 11/10/2026.
//

import Foundation

/// What students say about a lecture across all of its reviews, as the on-device
/// model reads them: an overview, what they liked and disliked, and how the
/// workload and grading come across.
///
/// Snapshots arrive while the model is still writing, which is why every field
/// is optional or grows as it goes.
public struct LectureReviewDigest: Equatable, Sendable {
  /// One or two sentences on the overall impression.
  public var overview: String?
  public var liked: [String]
  public var disliked: [String]
  public var workload: String?
  public var grading: String?

  public init(
    overview: String? = nil,
    liked: [String] = [],
    disliked: [String] = [],
    workload: String? = nil,
    grading: String? = nil
  ) {
    self.overview = overview
    self.liked = liked
    self.disliked = disliked
    self.workload = workload
    self.grading = grading
  }
}

/// How far a review digest has got. Reviews that do not fit in the model's
/// context at once are read in batches first, which takes a while, so the batches
/// are reported before the digest itself starts streaming in.
public enum LectureReviewDigestProgress: Equatable, Sendable {
  /// The first update: how many of the reviews will be read. Popular lectures
  /// have more than are worth reading, so it can be fewer than were given.
  case started(reviewCount: Int)
  /// `completed` of `total` batches of reviews have been read.
  case reading(completed: Int, total: Int)
  /// The digest as written so far.
  case writing(LectureReviewDigest)
}

/// Why reviews could not be summarised. Only `failed` is worth retrying
/// unchanged.
public enum LectureReviewDigestError: Error, Equatable, Sendable {
  /// The device doesn't support Apple Intelligence, it is switched off, or the
  /// model is still downloading.
  case unavailable
  /// There were no reviews with any text to read.
  case noReviews
  /// The reviews tripped the model's safety guardrails.
  case unsafeContent
  case failed
}
