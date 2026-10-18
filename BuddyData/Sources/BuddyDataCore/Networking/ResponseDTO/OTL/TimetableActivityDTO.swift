import Foundation
import BuddyDomain

struct TimetableActivityListDTO: Decodable {
  let customBlocks: [TimetableActivityDTO]
  enum CodingKeys: String, CodingKey { case customBlocks = "custom_blocks" }
}

struct TimetableActivityDTO: Decodable {
  struct TimeDTO: Decodable {
    let day: DayType
    let begin: Int
    let end: Int
  }

  let id: Int
  let blockName: String
  let place: String
  let day: DayType
  let begin: Int
  let end: Int
  /// Every time range; the legacy `day`/`begin`/`end` repeat only the first.
  /// Absent from servers that predate multi-range blocks.
  let times: [TimeDTO]?

  enum CodingKeys: String, CodingKey {
    case id, place, day, begin, end, times
    case blockName = "block_name"
  }

  func toModel() -> TimetableActivity {
    let ranges = times.flatMap { $0.isEmpty ? nil : $0 } ?? [.init(day: day, begin: begin, end: end)]
    return .init(
      id: id,
      title: blockName,
      location: place,
      times: ranges.map { .init(day: $0.day, begin: $0.begin, end: $0.end) }
    )
  }
}
