//
//  OTLV2CourseTarget.swift
//  BuddyData
//
//  Created by Soongyu Kwon on 07/03/2026.
//

import Foundation
import Moya

public enum OTLV2CourseTarget {
  case searchCourse(request: CourseSearchRequestDTO)
  case fetchCourse(courseID: Int)
}

extension OTLV2CourseTarget: TargetType, AccessTokenAuthorizable {
  public var baseURL: URL {
    BackendURL.otlBackendURL
  }

  public var path: String {
    switch self {
    case .searchCourse:
      "/api/v2/courses"
    case .fetchCourse(let courseID):
      "/api/v2/courses/\(courseID)"
    }
  }

  public var method: Moya.Method {
    switch self {
    case .searchCourse, .fetchCourse:
        .get
    }
  }

  public var task: Moya.Task {
    switch self {
    case .searchCourse(let request):
        .requestParameters(parameters: [
          "order": "code",
          "keyword": request.keyword,
          "limit": request.limit,
          "offset": request.offset
        ], encoding: URLEncoding.default)
    case .fetchCourse:
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
