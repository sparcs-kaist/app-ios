//
//  FCMTarget.swift
//  BuddyData
//
//  Created by 하정우 on 2/4/26.
//

import Foundation
import Moya

public enum FCMTarget {
  case register(deviceUUID: String, fcmToken: String, deviceName: String, language: String)
  case manage(service: Int, isActive: Bool)
}

extension FCMTarget: TargetType, AccessTokenAuthorizable {
  public var baseURL: URL {
    BackendURL.feedBackendURL
  }
  
  public var path: String {
    switch self {
    case .register:
      "/notification/device_info/"
    case .manage:
      "/notification/manage_alert/"
    }
  }
  
  public var method: Moya.Method {
    .post
  }
  
  public var task: Moya.Task {
    switch self {
    case .register(let deviceUUID, let fcmToken, let deviceName, let language):
        .requestParameters(parameters: ["device_uuid": deviceUUID, "fcm_token": fcmToken, "device_name": deviceName, "app_language": language], encoding: JSONEncoding.default)
    case .manage(let service, let isActive):
        .requestParameters(parameters: ["service": service, "is_active": isActive], encoding: JSONEncoding.default)
    }
  }
  
  public var headers: [String : String]? {
    [
      "Origin": "sparcsapp",
      "Content-Type": "application/json"
    ]
  }
  
  public var authorizationType: Moya.AuthorizationType? {
    .bearer
  }
}
