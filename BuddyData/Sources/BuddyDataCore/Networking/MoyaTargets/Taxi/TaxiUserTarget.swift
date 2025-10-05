//
//  TaxiUserTarget.swift
//  soap
//
//  Created by Soongyu Kwon on 12/07/2025.
//

import Foundation
import Moya

public enum TaxiUserTarget {
  case fetchUserInfo
  case editBankAccount(account: String)
  case fetchReports
}

extension TaxiUserTarget: TargetType, AccessTokenAuthorizable {
  public var baseURL: URL {
    BackendURL.taxiBackendURL
  }

  public var path: String {
    switch self {
    case .fetchUserInfo:
      "/logininfo"
    case .editBankAccount:
      "/users/editAccount"
    case .fetchReports:
      "/reports/searchByUser"
    }
  }

  public var method: Moya.Method {
    switch self {
    case .fetchUserInfo:
      .get
    case .editBankAccount:
      .post
    case .fetchReports:
      .get
    }
  }

  public var task: Moya.Task {
    switch self {
    case .fetchUserInfo:
      .requestPlain
    case let .editBankAccount(account):
      .requestParameters(parameters: ["account": account], encoding: JSONEncoding.default)
    case .fetchReports:
      .requestPlain
    }
  }

  public var headers: [String: String]? {
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

  public var authorizationType: Moya.AuthorizationType? {
    .bearer
  }
}
