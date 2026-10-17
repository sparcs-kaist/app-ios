import Testing
import Foundation
import BuddyDomain
@testable import BuddyDataCore

@Suite("Class reminder schedule")
struct ClassReminderScheduleTests {
  private let block = TimetableActivity(id: 17, title: "SPARCS Meeting", location: "Club Room", day: .mon, begin: 1140, end: 1200)

  @Test func lectureMeetingsAndBlocksBecomeSlotsInWeeklyOrder() {
    let timetable = Timetable(id: "1", lectures: [.mock], activities: [block])
    let slots = ClassReminderSchedule.slots(of: timetable)

    #expect(slots.map(\.id) == ["L10101:0", "A17", "L10101:1"])
    #expect(slots.map(\.day) == [0, 0, 2])

    let lecture = slots[0]
    #expect(lecture.title == "System Programming")
    #expect(lecture.begin == 540 && lecture.end == 630)
    #expect(lecture.buildingCode == "E11")
    #expect(lecture.room == "304")
    #expect(lecture.kind == "lecture")
    #expect(lecture.colorID == Lecture.mock.courseID)

    let activity = slots[1]
    #expect(activity.buildingCode == nil)
    #expect(activity.room == nil)
    #expect(activity.buildingName == "Club Room")
    #expect(activity.kind == "activity")
    #expect(activity.colorID == 17)
  }

  @Test func encodesSnakeCaseWithExplicitNulls() throws {
    let slot = ClassReminderSchedule.slots(of: Timetable(id: "1", lectures: [], activities: [block]))[0]
    let json = try JSONSerialization.jsonObject(with: JSONEncoder().encode(slot)) as? [String: Any]

    #expect(json?["building_code"] is NSNull)
    #expect(json?["room"] is NSNull)
    #expect(json?["building_name"] as? String == "Club Room")
    #expect(json?["color_id"] as? Int == 17)
  }

  @Test func semesterNumbersFollowOTL() {
    #expect(ClassReminderSchedule.otlNumber(of: .spring) == 1)
    #expect(ClassReminderSchedule.otlNumber(of: .autumn) == 3)
    #expect(ClassReminderSchedule.otlNumber(of: .winter) == 4)
  }
}
