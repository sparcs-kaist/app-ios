import Foundation

public enum FeedPageDecoder {
  public static func decode(_ data: Data) throws -> FeedPostPage {
    try JSONDecoder().decode(FeedPostPagePayload.self, from: data).toModel()
  }

  public static func decode(_ json: String) throws -> FeedPostPage {
    try decode(Data(json.utf8))
  }
}
