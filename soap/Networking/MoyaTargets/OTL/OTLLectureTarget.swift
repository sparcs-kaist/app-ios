//
//  OTLLectureTarget.swift
//  soap
//
//  Created by Soongyu Kwon on 30/09/2025.
//

import Foundation
import Moya

enum OTLLectureTarget {
  case searchLecture(request: LectureSearchRequestDTO)
  case fetchReviews(lectureID: Int)
}

extension OTLLectureTarget: TargetType, AccessTokenAuthorizable {
  var baseURL: URL {
    Constants.otlBackendURL
  }

  var path: String {
    switch self {
    case .searchLecture:
      "/api/lectures"
    case .fetchReviews(let lectureID):
      "/api/lectures/\(lectureID)/related-reviews"
    }
  }

  var method: Moya.Method {
    switch self {
    case .searchLecture, .fetchReviews:
        .get
    }
  }

  var task: Moya.Task {
    switch self {
    case .searchLecture(let request):
        .requestParameters(parameters: [
          "year": request.year,
          "semester": request.semester,
          "keyword": request.keyword,
          "type": request.type,
          "department": request.department,
          "level": request.level,
          "limit": request.limit,
          "offset": request.offset
        ], encoding: URLEncoding.default)
    case .fetchReviews:
        .requestParameters(parameters: [
          "order": "-written_datetime",
          "limit": 150
        ], encoding: URLEncoding.default)
    }
  }

  var headers: [String: String]? {
    [
      "Content-Type": "application/json"
    ]
  }

  var authorizationType: Moya.AuthorizationType? {
    .bearer
  }
}
