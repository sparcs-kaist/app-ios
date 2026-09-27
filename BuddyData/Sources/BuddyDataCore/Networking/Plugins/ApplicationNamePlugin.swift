//
//  ApplicationNamePlugin.swift
//  BuddyData
//

import Foundation
import Moya

public struct ApplicationNamePlugin: PluginType {
  public init() {}

  public func prepare(_ request: URLRequest, target: TargetType) -> URLRequest {
    var request = request
    request.setValue(BackendURL.applicationName, forHTTPHeaderField: "X-Application-Name")
    return request
  }
}
