//
//  OTLV2LectureTarget.swift
//  BuddyData
//
//  Created by Soongyu Kwon on 06/03/2026.
//

import Foundation
import Moya

public enum OTLV2LectureTarget {
  case searchLecture(request: LectureSearchRequestDTO)
}

extension OTLV2LectureTarget: TargetType, AccessTokenAuthorizable {
  public var baseURL: URL {
    BackendURL.otlBackendURL
  }

  public var path: String {
    switch self {
    case .searchLecture:
      "/api/v2/lectures"
    }
  }

  public var method: Moya.Method {
    switch self {
    case .searchLecture:
        .get
    }
  }

  public var task: Moya.Task {
    switch self {
    case .searchLecture(let request):
        .requestParameters(parameters: [
          "year": request.year,
          "semester": request.semester,
          "keyword": request.keyword,
          "limit": request.limit,
          "offset": request.offset
        ], encoding: URLEncoding.default)

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
