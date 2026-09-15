import Foundation
import Moya

public enum TimetableThemeTarget {
  case share(TimetableThemeRequestDTO)
  case fetch(code: String)
}

extension TimetableThemeTarget: TargetType, AccessTokenAuthorizable {
  public var baseURL: URL {
    return BackendURL.feedBackendURL
  }
  public var path: String {
    switch self {
    case .share: "/timetable-themes/shares"
    case .fetch(let code): "/timetable-themes/shares/\(code)"
    }
  }
  public var method: Moya.Method {
    switch self {
    case .share: .post
    case .fetch: .get
    }
  }
  public var task: Moya.Task {
    switch self {
    case .share(let theme): .requestJSONEncodable(theme)
    case .fetch: .requestPlain
    }
  }
  public var headers: [String: String]? { ["Content-Type": "application/json"] }
  public var authorizationType: Moya.AuthorizationType? { .bearer }
}
