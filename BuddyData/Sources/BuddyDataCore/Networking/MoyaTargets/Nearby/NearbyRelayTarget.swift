//
//  NearbyRelayTarget.swift
//  BuddyData
//
//  Created by Soongyu Kwon on 04/10/2026.
//

import Foundation
import Moya

/// The nearby relay on the Buddy backend. Sends the Buddy token (the relay
/// requires sign-in) but never OTL credentials; owner-only calls add the
/// session's `X-Owner-Secret`.
public enum NearbyRelayTarget {
  case putPresence(lookupId: String, request: NearbyPutPresenceRequestDTO, ownerSecret: String)
  case batchGet(request: NearbyBatchGetRequestDTO)
  case deletePresence(lookupId: String, ownerSecret: String)
  case postMessage(lookupId: String, request: NearbyPostMessageRequestDTO)
  case pollMessages(lookupId: String, ownerSecret: String, after: String?, wait: Int)
}

extension NearbyRelayTarget: TargetType, AccessTokenAuthorizable {
  public var baseURL: URL {
    BackendURL.feedBackendURL
  }

  public var path: String {
    switch self {
    case .putPresence(let lookupId, _, _), .deletePresence(let lookupId, _):
      "/nearby/presences/\(lookupId)"
    case .batchGet:
      "/nearby/presences:batchGet"
    case .postMessage(let lookupId, _), .pollMessages(let lookupId, _, _, _):
      "/nearby/presences/\(lookupId)/messages"
    }
  }

  public var method: Moya.Method {
    switch self {
    case .putPresence:
      .put
    case .batchGet, .postMessage:
      .post
    case .deletePresence:
      .delete
    case .pollMessages:
      .get
    }
  }

  public var task: Moya.Task {
    switch self {
    case .putPresence(_, let request, _):
      .requestJSONEncodable(request)
    case .batchGet(let request):
      .requestJSONEncodable(request)
    case .postMessage(_, let request):
      .requestJSONEncodable(request)
    case .deletePresence:
      .requestPlain
    case .pollMessages(_, _, let after, let wait):
      .requestParameters(
        parameters: ["after": after ?? "0", "wait": wait],
        encoding: URLEncoding.queryString
      )
    }
  }

  public var headers: [String: String]? {
    var headers = ["Content-Type": "application/json"]
    switch self {
    case .putPresence(_, _, let secret), .deletePresence(_, let secret), .pollMessages(_, let secret, _, _):
      headers["X-Owner-Secret"] = secret
    case .batchGet, .postMessage:
      break
    }
    return headers
  }

  public var authorizationType: Moya.AuthorizationType? {
    .bearer
  }
}
