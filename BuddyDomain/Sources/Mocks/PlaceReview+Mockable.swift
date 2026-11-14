//
//  PlaceReview+Mockable.swift
//  BuddyDomain
//
//  Created by Soongyu Kwon on 14/11/2026.
//

import Foundation

// Every review here is made up for design work. They are generated from the place's ID, so a place
// keeps the same reviews between launches.

extension PlaceReview: Mockable { }

public extension PlaceReview {
  static var mock: PlaceReview {
    mockList[0]
  }

  static var mockList: [PlaceReview] {
    CampusPlace.mockList.flatMap { reviews(for: $0) }
  }

  private static func reviews(for place: CampusPlace) -> [PlaceReview] {
    let templates = templates(for: place.category)
    guard !templates.isEmpty else { return [] }

    var generator = SeededGenerator(seed: place.id)
    // Places to eat are reviewed the most; one building in five has no reviews yet.
    let isDining = [.cafeteria, .restaurant, .cafe].contains(place.category)
    let count = isDining ? 3 + generator.next(5) : generator.next(5)
    let offset = generator.next(templates.count)
    var daysAgo = generator.next(4)

    return (0..<min(count, templates.count)).map { index in
      let template = templates[(offset + index) % templates.count]
      // One review in three comes with photos.
      let photoCount = generator.next(3) == 0 ? 1 + generator.next(3) : 0
      let photos = (0..<photoCount).map { photoIndex in
        PlacePhoto(id: "\(place.id)-\(index)-\(photoIndex)", hue: Double(generator.next(100)) / 100)
      }
      defer { daysAgo += 2 + generator.next(40) }
      return PlaceReview(
        id: "\(place.id)-\(index)",
        placeID: place.id,
        authorName: authors[generator.next(authors.count)],
        rating: template.rating,
        text: template.text,
        createdAt: Date.now.addingTimeInterval(-Double(daysAgo) * 86_400 - Double(generator.next(80_000))),
        photos: photos,
        upvotes: generator.next(4) == 0 ? 0 : generator.next(40)
      )
    }
  }

  private static let authors = [
    "Minjun", "Seoyeon", "Jiho", "Hayoon", "Alex", "Dohyun", "Yuna", "Sam", "Eunwoo", "Chaewon", "Priya", "Jisoo"
  ]

  private static func templates(for category: CampusPlaceCategory) -> [(rating: Int, text: String)] {
    switch category {
    case .cafeteria, .restaurant:
      [
        (5, "Best value on campus. The portions are generous and the line moves quickly even at noon."),
        (4, "Solid lunch spot. Gets crowded between 12 and 1, so come a little early."),
        (3, "It's fine. The menu repeats a lot, but it's close and cheap."),
        (5, "The spicy pork is worth the walk. Side dishes are refilled all the time."),
        (2, "Waited twenty minutes and the rice had run out. Go off-peak or not at all."),
        (4, "Friendly staff and the food comes out hot. Vegetarian options are limited."),
        (4, "Reliable when you don't want to leave campus. Card and student ID both work."),
        (1, "Cold soup and nowhere to sit. I won't be back this semester.")
      ]
    case .cafe:
      [
        (5, "Good espresso and plenty of sockets. My default place to work between lectures."),
        (4, "Nice iced americano. Seats fill up fast during exam weeks."),
        (3, "Drinks are okay but pricey for campus. Wi-Fi drops now and then."),
        (5, "The baristas remember your order. Quiet in the mornings."),
        (4, "Great for a quick meeting. Try the seasonal latte."),
        (2, "Too loud to study and the queue is long after 1 pm.")
      ]
    case .library:
      [
        (5, "Quiet, bright and open late. The group rooms are easy to book."),
        (4, "Good place to focus. It gets cold upstairs, so bring a jumper."),
        (4, "Plenty of seats outside exam season. Sockets at almost every desk."),
        (3, "Packed during finals. Come before 9 if you want a seat.")
      ]
    case .sportsField:
      [
        (5, "Well kept and rarely full in the evening. Lockers are free with a student ID."),
        (4, "Good equipment, though the peak hours after 6 are busy."),
        (3, "Decent, but the showers could be cleaner."),
        (4, "Nice track for a run. Lights stay on until late.")
      ]
    case .dormitory:
      [
        (4, "Rooms are small but clean, and it's a short walk to the cafeteria."),
        (3, "Thin walls. The laundry room is always busy on Sundays."),
        (5, "Recently renovated and warm in winter. The lounge is a nice place to study."),
        (2, "Hot water runs out in the morning rush.")
      ]
    case .store, .postOffice, .printShop, .hospital:
      [
        (4, "Quick and helpful. Usually no wait in the afternoon."),
        (5, "Staff went out of their way to help. Saved me a trip off campus."),
        (3, "Does the job, but it closes earlier than you'd expect."),
        (4, "Has what you need at fair prices. Gets busy at lunch.")
      ]
    case .building, .academicBuilding, .theater:
      [
        (4, "Easy to find and the lecture rooms are comfortable."),
        (5, "Lovely building with good study corners on the upper floors."),
        (3, "The lifts are slow between classes. Take the stairs."),
        (4, "Clean and well signposted. Vending machines on the ground floor.")
      ]
    case .olevStop, .gate, .parking:
      []
    }
  }
}

/// A small deterministic generator, so mock reviews don't change from one launch to the next.
private struct SeededGenerator {
  private var state: UInt64

  init(seed: String) {
    state = seed.unicodeScalars.reduce(1_469_598_103_934_665_603) { ($0 ^ UInt64($1.value)) &* 1_099_511_628_211 }
  }

  /// A number in `0..<upperBound`.
  mutating func next(_ upperBound: Int) -> Int {
    // SplitMix64: short, similar seeds such as "E1" and "E9" still give unrelated numbers.
    state &+= 0x9E37_79B9_7F4A_7C15
    var mixed = state
    mixed = (mixed ^ (mixed >> 30)) &* 0xBF58_476D_1CE4_E5B9
    mixed = (mixed ^ (mixed >> 27)) &* 0x94D0_49BB_1331_11EB
    mixed ^= mixed >> 31
    return Int(mixed % UInt64(upperBound))
  }
}
