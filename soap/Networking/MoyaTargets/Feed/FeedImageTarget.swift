//
//  FeedImageTarget.swift
//  soap
//
//  Created by Soongyu Kwon on 21/08/2025.
//

import Foundation
import Moya

enum FeedImageTarget {
  case uploadPostImage(imageData: Data, description: String, spoiler: Bool)
}

extension FeedImageTarget: TargetType, AccessTokenAuthorizable {
  var baseURL: URL {
    Constants.feedBackendURL
  }

  var path: String {
    switch self {
    case .uploadPostImage:
      "/images"
    }
  }

  var method: Moya.Method {
    switch self {
    case .uploadPostImage:
        .post
    }
  }

  var task: Moya.Task {
    switch self {
    case .uploadPostImage(let imageData, let description, let spoiler):
      var multipartData: [MultipartFormData] = [
        MultipartFormData(
          provider: .data(imageData),
          name: "file",
          fileName: "image.png",
          mimeType: "image/png"
        ),
        MultipartFormData(provider: .data(description.data(using: .utf8)!), name: "description"),
        MultipartFormData(provider: .data(Data((spoiler ? "true" : "false").utf8)), name: "spoiler")
      ]

      return .uploadMultipart(multipartData)
    }
  }

  var headers: [String: String]? {
    [
      "Origin": "sparcsapp",
      "Content-Type": "application/json"
    ]
  }

  var authorizationType: Moya.AuthorizationType? {
    .bearer
  }
}
