//
//  FeedImageTarget.swift
//  soap
//
//  Created by Soongyu Kwon on 21/08/2025.
//

import Foundation
import Moya
import BuddyDataCore

public enum FeedImageTarget {
  case uploadPostImage(imageData: Data, description: String, spoiler: Bool)
}

extension FeedImageTarget: TargetType, AccessTokenAuthorizable {
  public var baseURL: URL {
    BackendURL.feedBackendURL
  }

  public var path: String {
    switch self {
    case .uploadPostImage:
      "/images"
    }
  }

  public var method: Moya.Method {
    switch self {
    case .uploadPostImage:
        .post
    }
  }

  public var task: Moya.Task {
    switch self {
    case .uploadPostImage(let imageData, let description, let spoiler):
      let multipartData: [MultipartFormData] = [
        MultipartFormData(
          provider: .data(imageData),
          name: "file",
          fileName: "image.jpg",
          mimeType: "image/jpeg"
        ),
        MultipartFormData(provider: .data(description.data(using: .utf8)!), name: "description"),
        MultipartFormData(provider: .data(Data((spoiler ? "true" : "false").utf8)), name: "spoiler")
      ]

      return .uploadMultipart(multipartData)
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
