//
//  PlaceReview.swift
//  BuddyDomain
//
//  Created by Soongyu Kwon on 14/11/2026.
//

import Foundation

/// What someone wrote about a place: a star rating, a few words and, sometimes, photos.
///
/// A place has no photos of its own. The ones its card shows are gathered from its reviews.
public struct PlaceReview: Identifiable, Hashable, Sendable {
  public let id: String
  public let placeID: String
  public let authorName: String
  /// Whole stars, 1...5.
  public let rating: Int
  public let text: String
  public let createdAt: Date
  public let photos: [PlacePhoto]
  public var upvotes: Int
  /// Whether the signed-in user has upvoted it.
  public var isUpvoted: Bool
  /// Whether the signed-in user wrote it. A user has at most one review of a place.
  public let isMine: Bool

  public init(
    id: String,
    placeID: String,
    authorName: String,
    rating: Int,
    text: String,
    createdAt: Date,
    photos: [PlacePhoto] = [],
    upvotes: Int = 0,
    isUpvoted: Bool = false,
    isMine: Bool = false
  ) {
    self.id = id
    self.placeID = placeID
    self.authorName = authorName
    self.rating = rating
    self.text = text
    self.createdAt = createdAt
    self.photos = photos
    self.upvotes = upvotes
    self.isUpvoted = isUpvoted
    self.isMine = isMine
  }
}

/// A photo attached to a review. Mock photos carry no URL; the UI draws a placeholder tinted by `hue`.
public struct PlacePhoto: Identifiable, Hashable, Sendable {
  public let id: String
  public let url: URL?
  public let caption: String?
  /// 0...1, used to vary placeholders until real photos exist.
  public let hue: Double

  public init(id: String, url: URL? = nil, caption: String? = nil, hue: Double) {
    self.id = id
    self.url = url
    self.caption = caption
    self.hue = hue
  }
}

/// A place's reviews added up: the average, and how many gave each number of stars.
public struct PlaceRatingSummary: Hashable, Sendable {
  public let average: Double
  public let count: Int
  /// Reviews per star, index 0 for one star through index 4 for five.
  public let distribution: [Int]

  /// Nil when there is nothing to average.
  public init?(reviews: [PlaceReview]) {
    guard !reviews.isEmpty else { return nil }
    self.count = reviews.count
    self.average = Double(reviews.reduce(0) { $0 + $1.rating }) / Double(reviews.count)
    self.distribution = (1...5).map { stars in reviews.count { $0.rating == stars } }
  }
}
