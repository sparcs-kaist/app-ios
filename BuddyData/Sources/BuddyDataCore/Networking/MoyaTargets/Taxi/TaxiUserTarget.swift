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
  case editBadge(badge: Bool)
  case editBankAccount(account: String)
  case fetchReports
  case registerPhoneNumber(phoneNumber: String)
  case editNickname(nickname: String)
}

extension TaxiUserTarget: TargetType, AccessTokenAuthorizable {
  public var baseURL: URL {
    BackendURL.taxiBackendURL
  }

  public var path: String {
    switch self {
    case .fetchUserInfo:
      "/logininfo"
    case .editBadge:
      "/users/editBadge"
    case .editBankAccount:
      "/users/editAccount"
    case .fetchReports:
      "/reports/searchByUser"
    case .registerPhoneNumber:
      "/users/registerPhoneNumber"
    case .editNickname:
      "/users/editNickname"
    }
  }

  public var method: Moya.Method {
    switch self {
    case .fetchUserInfo, .fetchReports:
      .get
    case .editBadge, .editBankAccount, .registerPhoneNumber, .editNickname:
      .post
    }
  }

  public var task: Moya.Task {
    switch self {
    case .fetchUserInfo:
      .requestPlain
    case let .editBadge(badge):
      .requestParameters(parameters: ["badge": "\(badge)"], encoding: JSONEncoding.default)
    case let .editBankAccount(account):
      .requestParameters(parameters: ["account": account], encoding: JSONEncoding.default)
    case .fetchReports:
      .requestPlain
    case let .registerPhoneNumber(number):
      .requestParameters(parameters: ["phoneNumber": number], encoding: JSONEncoding.default)
    case let .editNickname(nickname):
      .requestParameters(parameters: ["nickname": nickname], encoding: JSONEncoding.default)
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
