import Testing
import BuddyDomain

@Suite("Timetable conflicts")
struct TimetableConflictTests {
  private func lecture(id: Int, name: String, _ slots: [(DayType, Int, Int)]) -> Lecture {
    Lecture(
      id: id, courseID: id, section: "A", name: name, subtitle: "", code: "CS.\(id)",
      department: Department(id: 1, name: "School of Computing"), type: .me,
      capacity: 40, enrolledCount: 0, credit: 3, creditAU: 0, grade: 0, load: 0, speech: 0,
      isEnglish: false, professors: [],
      classes: slots.map { LectureClass(day: $0.0, begin: $0.1, end: $0.2, buildingCode: "", buildingName: "", roomName: "") },
      exams: [], classDuration: 3, expDuration: 0
    )
  }

  private var timetable: Timetable {
    Timetable(
      id: "1",
      lectures: [lecture(id: 1, name: "Algorithms", [(.mon, 630, 720), (.wed, 630, 720)])],
      activities: [TimetableActivity(id: 7, title: "Club", location: "", day: .fri, begin: 780, end: 900)]
    )
  }

  @Test func findsOverlappingLecturesAndActivities() {
    let candidate = lecture(id: 2, name: "Databases", [(.wed, 690, 780), (.fri, 840, 900)])
    #expect(timetable.conflicts(with: candidate) == ["Algorithms", "Club"])
  }

  @Test func returnsTheOverlappingItemsToReplace() {
    let candidate = lecture(id: 2, name: "Databases", [(.wed, 690, 780), (.fri, 840, 900)])
    let overlapping = timetable.overlapping(with: candidate)
    #expect(overlapping.lectures.map(\.id) == [1])
    #expect(overlapping.activities.map(\.id) == [7])
    let clear = timetable.overlapping(with: lecture(id: 3, name: "OS", [(.tue, 540, 630)]))
    #expect(clear.lectures.isEmpty && clear.activities.isEmpty)
  }

  @Test func everyActivityTimeRangeCountsAndLaysOut() {
    var table = timetable
    table.activities = [TimetableActivity(id: 8, title: "Study", location: "", times: [
      .init(day: .tue, begin: 540, end: 600),
      .init(day: .thu, begin: 840, end: 900),
    ])]
    let candidate = lecture(id: 2, name: "Databases", [(.thu, 870, 960)])
    #expect(table.overlapping(with: candidate).activities.map(\.id) == [8])
    #expect(table.hasCollision(with: candidate))
    #expect(table.activitySlots(day: .thu).map(\.id) == ["8-1"])
    #expect(table.activitySlots(day: .tue).map(\.begin) == [540])
    #expect(table.visibleDays.contains(.thu))
    #expect(table.maxMinutes == 900)
  }

  @Test func touchingEdgesDoNotConflict() {
    let candidate = lecture(id: 2, name: "Databases", [(.mon, 720, 810), (.fri, 690, 780)])
    #expect(timetable.conflicts(with: candidate).isEmpty)
  }

  @Test func addedLectureDoesNotConflictWithItself() {
    let added = timetable.lectures[0]
    #expect(timetable.contains(added))
    #expect(timetable.conflicts(with: added).isEmpty)
  }
}
