//
//  LectureReviewBatching.swift
//  BuddyDataCore
//
//  Created by Soongyu Kwon on 11/10/2026.
//

import Foundation
import BuddyDomain

/// Prepares a lecture's reviews for the on-device model, whose context holds
/// only a few thousand tokens: the most useful reviews first, each on one line
/// with its ratings, packed into batches that each fit the context.
public enum LectureReviewBatching {
  /// Reviews past this many characters are cut short, so no one review crowds
  /// out the rest of its batch.
  public static let maximumReviewLength = 600
  /// Reading every review of a popular lecture would take minutes, and the
  /// most-liked ones already say what the rest do.
  public static let maximumBatches = 3

  /// One line per review that has anything to read, most-liked first and then
  /// newest first, each prefixed with its letter ratings.
  public static func lines(for reviews: [LectureReview]) -> [String] {
    reviews
      .filter { !$0.isDeleted }
      .map { (review: $0, text: normalized($0.content)) }
      .filter { !$0.text.isEmpty }
      .sorted { lhs, rhs in
        if lhs.review.like != rhs.review.like { return lhs.review.like > rhs.review.like }
        return lhs.review.year > rhs.review.year
      }
      .map { review, text in
        let ratings = "Grade \(review.grade), Load \(review.load), Speech \(review.speech)"
        return "- [\(ratings)] \(text)"
      }
  }

  /// Packs lines into batches costing at most `budget` each, in order, and
  /// stops after ``maximumBatches``. A line that costs more than the budget on
  /// its own still gets a batch of its own rather than being dropped.
  public static func batches(
    of lines: [String],
    budget: Int,
    cost: (String) async -> Int
  ) async -> [[String]] {
    var batches: [[String]] = []
    var current: [String] = []
    var currentCost = 0

    for line in lines {
      let lineCost = await cost(line)
      if !current.isEmpty, currentCost + lineCost > budget {
        batches.append(current)
        if batches.count == maximumBatches { return batches }
        current = []
        currentCost = 0
      }
      current.append(line)
      currentCost += lineCost
    }
    if !current.isEmpty {
      batches.append(current)
    }
    return batches
  }

  /// A deliberately high guess at the tokens in `text`, for systems that cannot
  /// count them: Hangul and other non-Latin text is about a token a character,
  /// Latin text about a token every three.
  public static func estimatedTokens(_ text: String) -> Int {
    var ascii = 0
    var other = 0
    for scalar in text.unicodeScalars {
      if scalar.isASCII { ascii += 1 } else { other += 1 }
    }
    return other + (ascii + 2) / 3
  }

  /// Collapses line breaks and runs of spaces, so a review stays on one line,
  /// and cuts it to ``maximumReviewLength``.
  private static func normalized(_ content: String) -> String {
    let words = content.split(whereSeparator: \.isWhitespace)
    let text = words.joined(separator: " ")
    guard text.count > maximumReviewLength else { return text }
    return text.prefix(maximumReviewLength) + "…"
  }
}
