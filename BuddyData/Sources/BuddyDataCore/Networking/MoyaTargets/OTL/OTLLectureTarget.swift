//
//  OTLLectureTarget.swift
//  BuddyData
//
//  Created by Soongyu Kwon on 06/03/2026.
//

import Foundation
import Moya

public enum OTLLectureTarget {
  case searchLecture(request: LectureSearchRequestDTO)
  case fetchUserLectureHistory(userID: Int)
}

extension OTLLectureTarget: TargetType, AccessTokenAuthorizable {
  public var baseURL: URL {
    BackendURL.otlBackendURL
  }

  public var path: String {
    switch self {
    case .searchLecture:
      "/api/v2/lectures"
    case .fetchUserLectureHistory(let userID):
      "/api/v2/users/\(userID)/lectures"
    }
  }

  public var method: Moya.Method {
    switch self {
    case .searchLecture:
        .get
    case .fetchUserLectureHistory:
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
    case .fetchUserLectureHistory:
        .requestPlain
    }
  }

  public var headers: [String: String]? {
    var headers = [
      "Content-Type": "application/json",
      "Accept-Language": Bundle.main.preferredLocalizations.first ?? "ko"
    ]
    
    #if DEBUG
    if !OTLDebugSecrets.key.isEmpty {
      headers["X-SID-AUTH-TOKEN"] = OTLDebugSecrets.key
    }
    #endif

    return headers
  }

  public var authorizationType: Moya.AuthorizationType? {
    .bearer
  }
}
