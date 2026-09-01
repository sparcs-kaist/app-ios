//
//  TaxiReportTarget.swift
//  soap
//
//  Created by 김민찬 on 8/11/25.
//

import Foundation
import Moya

public enum TaxiReportTarget {
  case fetchMyReports
  case createReport(with: TaxiCreateReportRequestDTO)
}

extension TaxiReportTarget: TargetType, AccessTokenAuthorizable {
  public var baseURL: URL {
    BackendURL.taxiBackendURL
  }
  
  public var path: String {
    switch self {
    case .fetchMyReports:
      "/reports/searchByUser"
    case .createReport:
      "/reports/create"
    }
  }
  
  public var method: Moya.Method {
    switch self {
    case .fetchMyReports:
      .get
    case .createReport:
      .post
    }
  }
  
  public var task: Moya.Task {
    switch self {
    case .fetchMyReports:
      .requestPlain
    case .createReport(let request):
      .requestJSONEncodable(request)
    }
  }
  
  public var headers: [String: String]? {
    [
      "Origin": "sparcsapp",
      "Content-Type": "application/json"
    ]
  }
  
  public var authorizationType: Moya.AuthorizationType? {
    .bearer
  }
}
