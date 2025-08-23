//
//  TaxiUserTarget.swift
//  soap
//
//  Created by Soongyu Kwon on 12/07/2025.
//

import Foundation
import Moya

enum TaxiUserTarget {
  case fetchUserInfo
  case editBankAccount(account: String)
  case fetchReports
}

extension TaxiUserTarget: TargetType, AccessTokenAuthorizable {
  var baseURL: URL {
    Constants.taxiBackendURL
  }

  var path: String {
    switch self {
    case .fetchUserInfo:
      "/logininfo"
    case .editBankAccount:
      "/users/editAccount"
    case .fetchReports:
      "/reports/searchByUser"
    }
  }

  var method: Moya.Method {
    switch self {
    case .fetchUserInfo:
      .get
    case .editBankAccount:
      .post
    case .fetchReports:
      .get
    }
  }

  var task: Moya.Task {
    switch self {
    case .fetchUserInfo:
      .requestPlain
    case let .editBankAccount(account):
      .requestParameters(parameters: ["account": account], encoding: JSONEncoding.default)
    case .fetchReports:
      .requestPlain
    }
  }

  var headers: [String: String]? {
    switch self {
    case .fetchUserInfo:      [
        "Origin": "sparcsapp",
        "Content-Type": "application/json"
      ]
    case .editBankAccount:      [
      "Origin": "sparcsapp",
      "Content-Type": "application/json"
      ]
    case .fetchReports:      [
      "Origin": "sparcsapp",
      "Content-Type": "application/json"
      ]
    }
  }

  var authorizationType: Moya.AuthorizationType? {
    .bearer
  }
}
