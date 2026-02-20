//
//  FeedProfileTarget.swift
//  BuddyDataiOS
//
//  Created by 하정우 on 2/20/26.
//

import Foundation
import BuddyDataCore
import Moya

public enum FeedProfileTarget {
  case setProfileImage(image: Data)
  case removeProfileImage
  case updateNickname(nickname: String)
}

extension FeedProfileTarget: TargetType, AccessTokenAuthorizable {
  public var baseURL: URL {
    BackendURL.feedBackendURL
  }
  
  public var path: String {
    switch self {
    case .setProfileImage, .removeProfileImage:
      "/me/profile-image"
    case .updateNickname:
      "/me"
    }
  }
  
  public var method: Moya.Method {
    switch self {
    case .setProfileImage:
      .post
    case .removeProfileImage:
      .delete
    case .updateNickname:
      .patch
    }
  }
  
  public var task: Moya.Task {
    switch self {
    case .setProfileImage(let image):
      .requestData(image)
    case .removeProfileImage:
      .requestPlain
    case .updateNickname(let nickname):
      .requestParameters(parameters: ["nickname": nickname], encoding: JSONEncoding.default)
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
