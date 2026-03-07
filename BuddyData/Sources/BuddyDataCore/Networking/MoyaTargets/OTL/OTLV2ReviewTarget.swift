//
//  OTLV2ReviewTarget.swift
//  BuddyData
//
//  Created by Soongyu Kwon on 07/03/2026.
//

import Foundation
import Moya

public enum OTLV2ReviewTarget {
  case fetchReviews(courseID: Int, professorID: Int, offset: Int, limit: Int)
  case writeReview(lectureID: Int, content: String, grade: Int, load: Int, speech: Int)
  case likeReview(reviewID: Int)
  case unlikeReview(reviewID: Int)
}

extension OTLV2ReviewTarget: TargetType, AccessTokenAuthorizable {
  public var baseURL: URL {
    BackendURL.otlBackendURL
  }

  public var path: String {
    switch self {
    case .fetchReviews, .writeReview:
      "/api/v2/reviews"
    case .likeReview(let reviewID), .unlikeReview(let reviewID):
      "/api/v2/reviews/\(reviewID)/liked"
    }
  }

  public var method: Moya.Method {
    switch self {
    case .fetchReviews:
        .get
    case .writeReview:
        .post
    case .likeReview, .unlikeReview:
        .patch
    }
  }

  public var task: Moya.Task {
    switch self {
    case .fetchReviews(let courseID, let professorID, let offset, let limit):
        .requestParameters(parameters: [
          "courseId": courseID,
          "professorId": professorID,
          "offset": offset,
          "limit": limit
        ], encoding: URLEncoding.default)
    case .writeReview(let lectureID, let content, let grade, let load, let speech):
        .requestParameters(parameters: [
          "lecture": lectureID,
          "content": content,
          "grade": grade,
          "load": load,
          "speech": speech
        ], encoding: JSONEncoding.default)
    case .likeReview, .unlikeReview:
        .requestPlain
    }
  }

  public var headers: [String: String]? {
    [
      "Content-Type": "application/json",
      "Accept-Language": Bundle.main.preferredLocalizations.first ?? "ko"
    ]
  }

  public var authorizationType: Moya.AuthorizationType? {
    .bearer
  }
}
