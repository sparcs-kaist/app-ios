//
//  OTLUserRepository.swift
//  soap
//
//  Created by Soongyu Kwon on 28/09/2025.
//

import Foundation
import BuddyDomain

@preconcurrency
import Moya

public final class OTLUserRepository: OTLUserRepositoryProtocol, Sendable {
  private let provider: MoyaProvider<OTLUserTarget>

  public init(provider: MoyaProvider<OTLUserTarget>) {
    self.provider = provider
  }

  public func register(ssoInfo: String) async throws {
    let response = try await provider.request(.register(ssoInfo: ssoInfo))
    _ = try response.filterSuccessfulStatusCodes()
  }

  public func fetchUser() async throws -> OTLUser {
    let response = try await provider.request(.fetchUserInfo)
    let result = try response.map(OTLUserDTO.self).toModel()

    return result
  }

  public func updateInterestedDepartments(userID: Int, departmentIDs: [Int]) async throws {
    _ = try await provider.request(.updateInterestedDepartments(userID: userID, departmentIDs: departmentIDs))
  }

  public func fetchWishlist(userID: Int, semester: Semester) async throws -> [CourseLecture] {
    let response = try await provider.request(
      .fetchWishlist(userID: userID, year: semester.year, semester: semester.semesterType.intValue)
    )
    let result = try response.map(CourseLecturePageDTO.self)

    return result.courses.map { $0.toModel().withoutRatings }
  }

  public func updateWishlist(userID: Int, lectureID: Int, isWishlisted: Bool) async throws {
    _ = try await provider.request(.updateWishlist(userID: userID, lectureID: lectureID, isWishlisted: isWishlisted))
  }
}

private extension CourseLecture {
  /// The wishlist endpoint fills its rating fields with review sums rather than averages, so
  /// they cannot be shown. Clearing them keeps wrong letters off the screen until it is fixed.
  var withoutRatings: CourseLecture {
    CourseLecture(
      id: id,
      name: name,
      code: code,
      type: type,
      lectures: lectures.map { lecture in
        Lecture(
          id: lecture.id, courseID: lecture.courseID, section: lecture.section, name: lecture.name,
          subtitle: lecture.subtitle, code: lecture.code, department: lecture.department, type: lecture.type,
          capacity: lecture.capacity, enrolledCount: lecture.enrolledCount, credit: lecture.credit,
          creditAU: lecture.creditAU, grade: 0, load: 0, speech: 0, isEnglish: lecture.isEnglish,
          professors: lecture.professors, classes: lecture.classes, exams: lecture.exams,
          classDuration: lecture.classDuration, expDuration: lecture.expDuration
        )
      },
      completed: completed
    )
  }
}
