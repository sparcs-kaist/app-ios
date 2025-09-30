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
}

extension OTLCourseTarget: TargetType {
  var baseURL: URL {
    Constants.otlBackendURL
  }
  
  var path: String {
    switch self {
    case .searchCourse:
      "/api/courses"
    case .getCourseReview(let courseId, _, _):
      "/api/courses/\(courseId)/reviews"
    }
  }
  
  var method: Moya.Method {
    switch self {
    case .searchCourse, .getCourseReview:
      .get
    }
  }
  
  var task: Moya.Task {
    switch self {
    case .searchCourse(let name, let offset, let limit):
      .requestParameters(parameters: ["keyword": name, "offset": offset, "limit": limit], encoding: URLEncoding.default)
    case .getCourseReview(_, let offset, let limit):
      .requestParameters(parameters: ["offset": offset, "limit": limit], encoding: URLEncoding.default)
    }
  }
  
  var headers: [String : String]? {
    [
      "Content-Type": "application/json"
    ]
  }
}
