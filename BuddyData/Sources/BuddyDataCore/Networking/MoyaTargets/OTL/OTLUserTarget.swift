//
//  OTLUserTarget.swift
//  soap
//
//  Created by Soongyu Kwon on 28/09/2025.
//

import Foundation
import Moya

public enum OTLUserTarget {
  case register(ssoInfo: String)
  case fetchUserInfo
  case updateInterestedDepartments(userID: Int, departmentIDs: [Int])
  case fetchWishlist(userID: Int, year: Int, semester: Int)
  case updateWishlist(userID: Int, lectureID: Int, isWishlisted: Bool)
}

extension OTLUserTarget: TargetType, AccessTokenAuthorizable {
  public var baseURL: URL {
    BackendURL.otlBackendURL
  }

  public var path: String {
    switch self {
    case .register:
      "/session/register-oneapp"
    case .fetchUserInfo:
      "/api/v2/users/info"
    case .updateInterestedDepartments(let userID, _):
      "/api/v2/users/\(userID)/interested-departments"
    case .fetchWishlist(let userID, _, _), .updateWishlist(let userID, _, _):
      "/api/v2/users/\(userID)/wishlist"
    }
  }

  public var method: Moya.Method {
    switch self {
    case .register:
      .post
    case .fetchUserInfo, .fetchWishlist:
      .get
    case .updateInterestedDepartments:
      .put
    case .updateWishlist:
      .patch
    }
  }

  public var task: Moya.Task {
    switch self {
    case .register(let ssoInfo):
        .requestParameters(parameters: ["sso_info": ssoInfo], encoding: JSONEncoding.default)
    case .fetchUserInfo:
        .requestPlain
    case .updateInterestedDepartments(_, let departmentIDs):
        .requestParameters(parameters: ["interestedDepartmentIds": departmentIDs], encoding: JSONEncoding.default)
    case .fetchWishlist(_, let year, let semester):
        .requestParameters(parameters: ["year": year, "semester": semester], encoding: URLEncoding.queryString)
    case .updateWishlist(_, let lectureID, let isWishlisted):
        .requestParameters(
          parameters: ["lectureId": lectureID, "mode": isWishlisted ? "add" : "delete"],
          encoding: JSONEncoding.default
        )
    }
  }

  public var headers: [String: String]? {
    var headers = [
      "Content-Type": "application/json"
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
