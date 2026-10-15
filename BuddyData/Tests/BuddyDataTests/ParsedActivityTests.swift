import Testing
import BuddyDomain

@Suite("Parsed activity")
struct ParsedActivityTests {
  private func parsed(
    title: String? = "Study group",
    location: String? = nil,
    startHour: Int? = nil,
    startMinute: Int? = nil,
    endHour: Int? = nil,
    endMinute: Int? = nil,
    durationMinutes: Int? = nil
  ) -> ParsedActivity {
    ParsedActivity(
      title: title,
      location: location,
      day: .tue,
      startHour: startHour,
      startMinute: startMinute,
      endHour: endHour,
      endMinute: endMinute,
      durationMinutes: durationMinutes
    )
  }

  @Test func clockTimesBecomeMinutesFromMidnight() {
    let activity = parsed(startHour: 19, startMinute: 30, endHour: 21, endMinute: 0)
    #expect(activity.begin == 19 * 60 + 30)
    #expect(activity.end == 21 * 60)
    #expect(activity.day == .tue)
  }

  @Test func missingMinutesMeanOnTheHour() {
    let activity = parsed(startHour: 9, endHour: 10)
    #expect(activity.begin == 9 * 60)
    #expect(activity.end == 10 * 60)
  }

  @Test func anEndBeforeTheStartIsReadTwelveHoursLater() {
    // "7 to 9" in the evening, with only the start read as evening.
    let activity = parsed(startHour: 19, endHour: 9)
    #expect(activity.begin == 19 * 60)
    #expect(activity.end == 21 * 60)
  }

  @Test func anEndThatCannotFitIsDropped() {
    let activity = parsed(startHour: 22, endHour: 0)
    #expect(activity.begin == 22 * 60)
    #expect(activity.end == nil)
  }

  @Test func aLengthIsUsedWithoutAnEndTime() {
    let activity = parsed(startHour: 14, durationMinutes: 90)
    #expect(activity.end == 15 * 60 + 30)
    #expect(parsed(startHour: 23, durationMinutes: 120).end == 24 * 60)
  }

  @Test func anEndTimeWinsOverALength() {
    let activity = parsed(startHour: 14, endHour: 15, durationMinutes: 90)
    #expect(activity.end == 15 * 60)
  }

  @Test func timesOutOfRangeAreLeftOut() {
    let activity = parsed(startHour: 25, endHour: 26)
    #expect(activity.begin == nil)
    #expect(activity.end == nil)
    #expect(parsed(startHour: 9, startMinute: 75).begin == 9 * 60 + 59)
  }

  @Test func anEndWithoutAStartIsLeftOut() {
    #expect(parsed(endHour: 10).end == nil)
  }

  @Test func blankTextIsLeftOut() {
    let activity = parsed(title: "  ", location: "\n")
    #expect(activity.title == nil)
    #expect(activity.location == nil)
    #expect(parsed(title: " Gym ", location: " N1 ").title == "Gym")
  }

  @Test func emptyOnlyWhenNothingIsFilledIn() {
    #expect(ParsedActivity().isEmpty)
    #expect(!ParsedActivity(day: .mon).isEmpty)
    #expect(!ParsedActivity(title: "Gym").isEmpty)
  }
}
