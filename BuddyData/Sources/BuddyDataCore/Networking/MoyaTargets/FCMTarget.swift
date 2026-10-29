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
  case unregister(deviceUUID: String)
  case notificationPreferences(deviceUUID: String)
  case setNotificationPreference(category: String, deviceUUID: String, isEnabled: Bool)
}

extension FCMTarget: TargetType, AccessTokenAuthorizable {
  public var baseURL: URL {
    BackendURL.feedBackendURL
  }
  
  public var path: String {
    switch self {
    case .register, .unregister:
      "/notification/device_info"
    case .notificationPreferences:
      "/notification/preferences"
    case .setNotificationPreference(let category, _, _):
      "/notification/preferences/\(category)"
    }
  }
  
  public var method: Moya.Method {
    switch self {
    case .register:
      .post
    case .unregister:
      .delete
    case .notificationPreferences:
      .get
    case .setNotificationPreference:
      .put
    }
  }
  
  public var task: Moya.Task {
    switch self {
    case .register(let deviceUUID, let fcmToken, let deviceName, let language):
        .requestParameters(parameters: ["device_uuid": deviceUUID, "fcm_token": fcmToken, "device_name": deviceName, "app_language": language], encoding: JSONEncoding.default)
    case .unregister(let deviceUUID), .notificationPreferences(let deviceUUID):
        .requestParameters(parameters: ["device_uuid": deviceUUID], encoding: URLEncoding.queryString)
    case .setNotificationPreference(_, let deviceUUID, let isEnabled):
        .requestParameters(parameters: ["device_uuid": deviceUUID, "is_enabled": isEnabled], encoding: JSONEncoding.default)
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
