//
//  TaxiNoticeTarget.swift
//  soap
//
//  Created by 하정우 on 8/14/25.
//

import Foundation
import Moya

enum TaxiNoticeTarget {
  case fetchNotice
}

extension TaxiNoticeTarget: TargetType {
  var baseURL: URL {
    Constants.taxiBackendURL
  }
  
  var path: String {
    switch self {
      case .fetchNotice:
       "/api/notice/list"
    }
  }
  
  var method: Moya.Method {
    switch self {
    case .fetchNotice:
      .get
    }
  }
  
  var task: Moya.Task {
    switch self {
      case .fetchNotice:
        .requestPlain
    }
  }
  
  var headers: [String: String]? {
    switch self {
      case .fetchNotice: [
        "Origin": "sparcsapp",
        "Content-Type": "application/json"
      ]
    }
  }
}
