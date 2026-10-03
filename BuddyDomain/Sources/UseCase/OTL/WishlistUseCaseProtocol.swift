//
//  WishlistUseCaseProtocol.swift
//  BuddyDomain
//
//  Created by Soongyu Kwon on 02/10/2026.
//

import Foundation

/// The lectures the signed-in user has saved for later, kept per user across semesters.
public protocol WishlistUseCaseProtocol: Sendable {
  /// The semester's wishlisted lectures, grouped by course.
  func fetchWishlist(semester: Semester) async throws -> [CourseLecture]
  func setWishlisted(_ isWishlisted: Bool, lectureID: Int) async throws
}
