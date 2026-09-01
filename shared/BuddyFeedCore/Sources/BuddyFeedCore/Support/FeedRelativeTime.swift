import Foundation

public enum FeedRelativeTime {
  public static func string(from date: Date, relativeTo now: Date = Date(), languageCode: String = "en") -> String {
    let seconds = max(0, Int(now.timeIntervalSince(date)))
    let korean = languageCode.lowercased().hasPrefix("ko")

    if seconds < 60 { return korean ? "방금 전" : "just now" }
    if seconds < 3_600 {
      let minutes = seconds / 60
      return korean ? "\(minutes)분 전" : "\(minutes) min ago"
    }
    if seconds < 86_400 {
      let hours = seconds / 3_600
      return korean ? "\(hours)시간 전" : "\(hours) hr\(hours == 1 ? "" : "s") ago"
    }
    if seconds < 604_800 {
      let days = seconds / 86_400
      return korean ? "\(days)일 전" : "\(days) day\(days == 1 ? "" : "s") ago"
    }
    return FeedISO8601.shortDate(from: date)
  }
}
