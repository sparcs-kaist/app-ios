//
//  OTLCourseTarget.swift
//  soap
//
//  Created by 하정우 on 10/1/25.
//

import Foundation
import Moya

enum OTLCourseTarget{
  case searchCourse(name: String, offset: Int, limit: Int)
  case getCourseReview(courseId: Int, offset: Int, limit: Int)
  case likeReview(reviewId: Int)
  case unlikeReview(reviewId: Int)
}

extension OTLCourseTarget: TargetType, AccessTokenAuthorizable {
  var baseURL: URL {
    Constants.otlBackendURL
  }
  
  var path: String {
    switch self {
    case .searchCourse:
      "/api/courses"
    case .getCourseReview(let courseId, _, _):
      "/api/courses/\(courseId)/reviews"
    case .likeReview(let reviewId), .unlikeReview(let reviewId):
      "/api/reviews/\(reviewId)/like"
    }
  }
  
  var method: Moya.Method {
    switch self {
    case .searchCourse, .getCourseReview:
      .get
    case .likeReview:
      .post
    case .unlikeReview:
      .delete
    }
  }
  
  var task: Moya.Task {
    switch self {
    case .searchCourse(let name, let offset, let limit):
      .requestParameters(parameters: ["keyword": name, "offset": offset, "limit": limit], encoding: URLEncoding.default)
    case .getCourseReview(_, let offset, let limit):
      .requestParameters(parameters: ["offset": offset, "limit": limit], encoding: URLEncoding.default)
    case .likeReview, .unlikeReview:
      .requestPlain
    }
  }
  
  var headers: [String : String]? {
    [
      "Content-Type": "application/json"
    ]
  }
  
  var authorizationType: AuthorizationType? {
    .bearer
  }
}
