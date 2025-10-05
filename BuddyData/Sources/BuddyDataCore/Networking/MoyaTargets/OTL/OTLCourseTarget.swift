//
//  OTLCourseTarget.swift
//  soap
//
//  Created by 하정우 on 10/1/25.
//

import Foundation
import Moya

public enum OTLCourseTarget{
  case searchCourse(name: String, offset: Int, limit: Int)
  case fetchReviews(courseId: Int, offset: Int, limit: Int)
  case likeReview(reviewId: Int)
  case unlikeReview(reviewId: Int)
}

extension OTLCourseTarget: TargetType, AccessTokenAuthorizable {
  public var baseURL: URL {
    BackendURL.otlBackendURL
  }
  
  public var path: String {
    switch self {
    case .searchCourse:
      "/api/courses"
    case .fetchReviews(let courseId, _, _):
      "/api/courses/\(courseId)/reviews"
    case .likeReview(let reviewId), .unlikeReview(let reviewId):
      "/api/reviews/\(reviewId)/like"
    }
  }
  
  public var method: Moya.Method {
    switch self {
    case .searchCourse, .fetchReviews:
      .get
    case .likeReview:
      .post
    case .unlikeReview:
      .delete
    }
  }
  
  public var task: Moya.Task {
    switch self {
    case .searchCourse(let name, let offset, let limit):
      .requestParameters(parameters: ["keyword": name, "offset": offset, "limit": limit], encoding: URLEncoding.default)
    case .fetchReviews(_, let offset, let limit):
      .requestParameters(parameters: ["offset": offset, "limit": limit], encoding: URLEncoding.default)
    case .likeReview, .unlikeReview:
      .requestPlain
    }
  }
  
  public var headers: [String : String]? {
    [
      "Content-Type": "application/json"
    ]
  }
  
  public var authorizationType: AuthorizationType? {
    .bearer
  }
}
