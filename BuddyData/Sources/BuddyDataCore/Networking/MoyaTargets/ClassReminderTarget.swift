//
//  ClassReminderTarget.swift
//  BuddyData
//
//  Created by Soongyu Kwon on 17/10/2026.
//

import Foundation
import Moya

public enum ClassReminderTarget {
  case putDevice(deviceUUID: String, body: ClassReminderDeviceRequestDTO)
  case deleteDevice(deviceUUID: String)
  case putActivity(activityID: String, body: ClassReminderActivityRequestDTO)
}

extension ClassReminderTarget: TargetType, AccessTokenAuthorizable {
  public var baseURL: URL {
    BackendURL.feedBackendURL
  }

  public var path: String {
    switch self {
    case .putDevice(let deviceUUID, _), .deleteDevice(let deviceUUID):
      "/live-activity/devices/\(deviceUUID)"
    case .putActivity(let activityID, _):
      "/live-activity/activities/\(activityID)"
    }
  }

  public var method: Moya.Method {
    switch self {
    case .putDevice, .putActivity: .put
    case .deleteDevice: .delete
    }
  }

  public var task: Moya.Task {
    switch self {
    case .putDevice(_, let body): .requestJSONEncodable(body)
    case .putActivity(_, let body): .requestJSONEncodable(body)
    case .deleteDevice: .requestPlain
    }
  }

  public var headers: [String: String]? {
    ["Content-Type": "application/json"]
  }

  public var authorizationType: Moya.AuthorizationType? {
    .bearer
  }
}
