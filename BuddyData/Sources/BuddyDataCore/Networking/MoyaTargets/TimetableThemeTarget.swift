import Foundation
import Moya
import BuddyDomain

public enum TimetableThemeTarget {
  case share(TimetableThemePayload)
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

public struct TimetableThemePayload: Codable, Sendable {
  let name: String
  let hexColors: [String]
  let textColorHex: String
  let separatorColorHex: String?
  let backgroundColorHex: String?
  let gridLabelColorHex: String?

  init(_ theme: TimetableTheme) {
    name = theme.displayName
    hexColors = theme.hexColors
    textColorHex = theme.textColorHex
    separatorColorHex = theme.separatorColorHex
    backgroundColorHex = theme.backgroundColorHex
    gridLabelColorHex = theme.gridLabelColorHex
  }

  func importedTheme() -> TimetableTheme {
    TimetableTheme(
      id: "custom.\(UUID().uuidString)", name: name, hexColors: hexColors,
      textColorHex: textColorHex, separatorColorHex: separatorColorHex,
      backgroundColorHex: backgroundColorHex, gridLabelColorHex: gridLabelColorHex
    )
  }
}

struct TimetableThemeShareResponse: Decodable {
  let code: String
  let theme: TimetableThemePayload
}
