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
  case writeReview(lectureID: Int, content: String, grade: Int, load: Int, speech: Int)
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
    case .writeReview:
      "/api/reviews"
    }
  }

  var method: Moya.Method {
    switch self {
    case .searchLecture, .fetchReviews:
        .get
    case .writeReview:
        .post
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
          "limit": 100
        ], encoding: URLEncoding.default)
    case .writeReview(let lectureID, let content, let grade, let load, let speech):
        .requestParameters(parameters: [
          "lecture": lectureID,
          "content": content,
          "grade": grade,
          "load": load,
          "speech": speech
        ], encoding: JSONEncoding.default)
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
