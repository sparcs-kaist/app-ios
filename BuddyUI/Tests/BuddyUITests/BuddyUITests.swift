import Foundation
import Testing
import BuddyDomain
@testable import TimetableUI

struct TimetableLayoutTests {
  private func classTime(_ begin: Int, _ end: Int, day: DayType = .mon) -> LectureClass {
    LectureClass(day: day, begin: begin, end: end, buildingCode: "E11", buildingName: "Building", roomName: "101")
  }

  private func item(_ begin: Int, _ end: Int) -> LectureItem {
    LectureItem(lecture: .mock, lectureClass: classTime(begin, end))
  }

  @Test(arguments: [1020, 1050, 1080])
  func widgetEndsAtCeilingOfLastClass(end: Int) {
    let layout = TimetableLayout(classes: [classTime(550, end)], placement: .widget)
    #expect(layout.startMinutes == 540)
    #expect(layout.endMinutes == ((end + 59) / 60) * 60)
  }

  @Test func appKeepsSpaceBelowAnExactHourEnding() {
    let layout = TimetableLayout(classes: [classTime(540, 1020)], placement: .view)
    #expect(layout.endMinutes == 1080)
  }

  @Test(arguments: [TimetablePlacement.view, .widget])
  func emptyTimetableHasWeekdayWorkingHours(placement: TimetablePlacement) {
    let layout = TimetableLayout(classes: [], placement: placement)
    #expect(layout.hours == 9..<18)
  }

  @Test func cellCoordinatesMatchTimeScale() {
    let lecture = item(570, 630)
    let layout = TimetableLayout(classes: [lecture.lectureClass], placement: .widget)
    // 120 minutes in 240 points, with a 30-point header.
    #expect(layout.offset(at: 540, height: 270) == 30)
    #expect(layout.offset(at: 570, height: 270) == 90)
    #expect(layout.offset(at: 660, height: 270) == 270)
    #expect(layout.cellHeight(for: lecture, height: 270) == 116)
  }

  @Test func shortContainersAndInvalidClassesDoNotProduceNegativeHeights() {
    let lecture = item(540, 541)
    let layout = TimetableLayout(classes: [lecture.lectureClass], placement: .widget)
    #expect(layout.cellHeight(for: lecture, height: 10) == 0)
    #expect(layout.cellHeight(for: lecture, height: 60) == 0)
    #expect(layout.offset(at: 540, height: 10).isFinite)
    #expect(TimetableLayout.cells(for: [item(600, 600), item(700, 600)]).isEmpty)
    #expect(TimetableLayout(classes: [classTime(600, 600)], placement: .widget).hours == 9..<18)
  }

  @Test func touchingAndIsolatedClassesKeepFullWidth() {
    let cells = TimetableLayout.cells(for: [item(600, 660), item(540, 600), item(720, 780)])
    #expect(cells.map(\.lane) == [0, 0, 0])
    #expect(cells.map(\.laneCount) == [1, 1, 1])
    #expect(cells.allSatisfy { $0.width(in: 100) == 100 })
  }

  @Test func overlapUsesTwoEqualColumnsAndLaterClassReturnsToFullWidth() {
    let cells = TimetableLayout.cells(for: [item(540, 630), item(600, 660), item(720, 780)])
    #expect(cells.map(\.lane) == [0, 1, 0])
    #expect(cells.map(\.laneCount) == [2, 2, 1])
    #expect(cells[0].width(in: 100) == 48)
    #expect(cells[1].x(in: 100) == 52)
    #expect(cells[2].width(in: 100) == 100)
  }

  @Test func overlapChainReusesMainColumnWhenAvailable() {
    let cells = TimetableLayout.cells(for: [item(540, 600), item(570, 660), item(630, 690)])
    #expect(cells.map(\.lane) == [0, 1, 0])
    #expect(cells.map(\.laneCount) == [2, 2, 2])
  }

  @Test func threeOrMoreSimultaneousClassesNeverCreateAThirdColumn() {
    let cells = TimetableLayout.cells(for: [item(540, 720), item(570, 690), item(600, 660), item(610, 650)])
    #expect(cells.map(\.lane) == [0, 1, 1, 1])
    #expect(cells.allSatisfy { $0.laneCount == 2 && $0.width(in: 100) == 48 })
  }

  @Test func equalStartTimesPreserveInputOrder() {
    let items = [item(540, 660), item(540, 600), item(540, 630)]
    let cells = TimetableLayout.cells(for: items)
    #expect(cells.map(\.id) == items.map(\.id))
    #expect(cells.map(\.lane) == [0, 1, 1])
  }
}
