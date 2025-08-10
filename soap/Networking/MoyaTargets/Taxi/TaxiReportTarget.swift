//
//  TaxiReportTarget.swift
//  soap
//
//  Created by 김민찬 on 8/11/25.
//

import Foundation
import Moya

enum TaxiReportTarget {
  case fetchMyReports
  case createReport(with: TaxiCreateReportRequestDTO)
}

extension TaxiReportTarget: TargetType, AccessTokenAuthorizable {
  var baseURL: URL {
    Constants.taxiBackendURL
  }
  
  var path: String {
    switch self {
    case .fetchMyReports:
      "/reports/searchByUser"
    case .createReport:
      "/reports/create"
    }
  }
  
  var method: Moya.Method {
    switch self {
    case .fetchMyReports:
      .get
    case .createReport:
      .post
    }
  }
  
  var task: Moya.Task {
    switch self {
    case .fetchMyReports:
      .requestPlain
    case .createReport(let request):
      .requestJSONEncodable(request)
    }
  }
  
  var headers: [String: String]? {
    [
      "Origin": "sparcsapp",
      "Content-Type": "application/json"
    ]
  }
  
  var authorizationType: Moya.AuthorizationType? {
    .bearer
  }
}
