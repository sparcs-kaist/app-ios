//
//  OTLDepartmentTarget.swift
//  BuddyData
//
//  Created by Soongyu Kwon on 14/03/2026.
//

import Foundation
import Moya

public enum OTLDepartmentTarget {
  case fetchDepartments
}

extension OTLDepartmentTarget: TargetType, AccessTokenAuthorizable {
  public var baseURL: URL {
    BackendURL.otlBackendURL
  }

  public var path: String {
    switch self {
    case .fetchDepartments:
      "/api/v2/department-options"
    }
  }

  public var method: Moya.Method {
    switch self {
    case .fetchDepartments:
        .get
    }
  }

  public var task: Moya.Task {
    switch self {
    case .fetchDepartments:
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
