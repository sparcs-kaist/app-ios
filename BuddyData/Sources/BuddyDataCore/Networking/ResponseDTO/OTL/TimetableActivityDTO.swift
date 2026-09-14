import Foundation
import BuddyDomain

struct TimetableActivityListDTO: Decodable {
  let customBlocks: [TimetableActivityDTO]
  enum CodingKeys: String, CodingKey { case customBlocks = "custom_blocks" }
}

struct TimetableActivityDTO: Decodable {
  let id: Int
  let blockName: String
  let place: String
  let day: DayType
  let begin: Int
  let end: Int

  enum CodingKeys: String, CodingKey {
    case id, place, day, begin, end
    case blockName = "block_name"
  }

  func toModel() -> TimetableActivity {
    .init(id: id, title: blockName, location: place, day: day, begin: begin, end: end)
  }
}
