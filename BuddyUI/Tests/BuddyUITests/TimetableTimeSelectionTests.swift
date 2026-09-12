import Testing
import BuddyDomain
@testable import TimetableUI

struct TimetableTimeSelectionTests {
  @Test func initializationSnapsAndKeepsPositiveDuration() {
    let selection = TimetableTimeSelection(day: .sat, begin: 547, end: 608)
    #expect(selection.day == .sat)
    #expect(selection.begin == 540)
    #expect(selection.end == 615)
    let reversed = TimetableTimeSelection(day: .mon, begin: 600, end: 540)
    #expect(reversed.begin == 600)
    #expect(reversed.end == 615)
  }

  @Test(arguments: [-120, 0, 15, 540, 1425, 1500])
  func movementPreservesDurationAndStaysInOneDay(start: Int) {
    let original = TimetableTimeSelection(day: .mon, begin: 540, end: 630)
    let moved = original.moving(to: start, on: .sun)
    #expect(moved.day == .sun)
    #expect(moved.duration == 90)
    #expect(moved.begin >= 0)
    #expect(moved.end <= TimetableTimeSelection.lastMinuteOfDay)
    #expect(moved.begin.isMultiple(of: 15))
    #expect(moved.end.isMultiple(of: 15))
  }

  @Test func resizeStartDoesNotMoveEndOrChangeDay() {
    let original = TimetableTimeSelection(day: .fri, begin: 540, end: 630)
    let resized = original.resizingStart(to: 572)
    #expect(resized.begin == 570)
    #expect(resized.end == 630)
    #expect(resized.day == .fri)
    #expect(original.resizingStart(to: 800).begin == 615)
    #expect(original.resizingStart(to: -30).begin == 0)
  }

  @Test func resizeEndDoesNotMoveStartOrCrossMidnight() {
    let original = TimetableTimeSelection(day: .fri, begin: 540, end: 630)
    let resized = original.resizingEnd(to: 658)
    #expect(resized.begin == 540)
    #expect(resized.end == 660)
    #expect(resized.day == .fri)
    #expect(original.resizingEnd(to: 500).end == 555)
    #expect(original.resizingEnd(to: 1800).end == 1425)
  }

  @Test func latestStartStillHasAtLeastFifteenMinutes() {
    let selection = TimetableTimeSelection(day: .sun, begin: 1440, end: 1500)
    #expect(selection.begin == 1410)
    #expect(selection.end == 1425)
    #expect(selection.duration == 15)
  }

  @Test func adjacentActivitiesDoNotOverlap() {
    let first = TimetableTimeSelection(day: .mon, begin: 540, end: 600)
    #expect(!first.overlaps(TimetableTimeSelection(day: .mon, begin: 600, end: 660)))
    #expect(!first.overlaps(TimetableTimeSelection(day: .tue, begin: 540, end: 600)))
    #expect(first.overlaps(TimetableTimeSelection(day: .mon, begin: 585, end: 660)))
    #expect(first.overlaps(first))
  }

  @Test func classConflictsIncludeContainmentButAllowTouchingEndpoints() {
    // The mock has Monday and Wednesday classes from 09:00 to 10:30.
    let timetable = Timetable(id: "test", lectures: [.mock])
    #expect(TimetableTimeSelection(day: .mon, begin: 540, end: 600).conflictingLectures(in: timetable).count == 1)
    #expect(TimetableTimeSelection(day: .mon, begin: 480, end: 660).conflictingLectures(in: timetable).count == 1)
    #expect(TimetableTimeSelection(day: .mon, begin: 480, end: 540).conflictingLectures(in: timetable).isEmpty)
    #expect(TimetableTimeSelection(day: .mon, begin: 630, end: 660).conflictingLectures(in: timetable).isEmpty)
    #expect(TimetableTimeSelection(day: .tue, begin: 540, end: 600).conflictingLectures(in: timetable).isEmpty)
    #expect(TimetableTimeSelection(day: .mon, begin: 540, end: 600).conflictingLectures(in: nil).isEmpty)
  }

  @Test func onlyTheManuallySelectedWeekendDayIsShown() {
    #expect(TimetableTimeSelection(day: .mon, begin: 540, end: 600).editingDays == DayType.weekdays)
    #expect(TimetableTimeSelection(day: .sat, begin: 540, end: 600).editingDays == DayType.weekdays + [.sat])
    #expect(TimetableTimeSelection(day: .sun, begin: 540, end: 600).editingDays == DayType.weekdays + [.sun])
  }
}
