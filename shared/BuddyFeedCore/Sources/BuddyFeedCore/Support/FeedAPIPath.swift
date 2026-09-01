import Foundation

public enum FeedAPIPath {
  public static let posts = "/posts"

  public static func post(_ postID: String) -> String { "/posts/\(postID)" }
  public static func vote(_ postID: String) -> String { "\(post(postID))/vote" }
  public static func report(_ postID: String) -> String { "\(post(postID))/report" }

  public static func postsURL(baseURL: String, cursor: String?, limit: Int) -> String? {
    guard var components = URLComponents(string: baseURL + posts) else { return nil }
    var queryItems = [URLQueryItem(name: "limit", value: String(limit))]
    if let cursor, !cursor.isEmpty {
      queryItems.append(URLQueryItem(name: "cursor", value: cursor))
    }
    components.queryItems = queryItems
    return components.url?.absoluteString
  }
}
