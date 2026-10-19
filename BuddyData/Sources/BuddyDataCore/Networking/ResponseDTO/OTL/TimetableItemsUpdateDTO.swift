import Foundation

/// What `PATCH /api/v2/timetables/{id}/items` reports: the item each change
/// touched, by the change's position in the request.
struct TimetableItemsUpdateDTO: Decodable {
  struct Result: Decodable {
    let index: Int
    let id: Int
  }

  let results: [Result]
}
