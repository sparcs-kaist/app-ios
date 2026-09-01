//
//  VersionTarget.swift
//  BuddyData
//
//  Created by 하정우 on 1/16/26.
//

import Foundation
import Moya

public enum VersionTarget {
  case getMinimumVersion
}

extension VersionTarget: TargetType {
  public var baseURL: URL {
    BackendURL.feedBackendURL
  }
  
  public var path: String {
    "/app_version/required"
  }
  
  public var method: Moya.Method {
    .get
  }
  
  public var task: Moya.Task {
    .requestPlain
  }
  
  public var headers: [String : String]? {
    [
      "Origin": "sparcsapp",
      "Content-Type": "application/json"
    ]
  }
}
