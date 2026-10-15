import Testing
import BuddyDomain

@Suite("Activity description scanner")
struct ActivityDescriptionScannerTests {
  private func times(_ text: String) -> [Int?]? {
    ActivityDescriptionScanner.times(in: text).map { [$0.begin, $0.end] }
  }

  // MARK: Days

  @Test(arguments: [
    ("월요일 21-22시 동안 SPARCS 정모", DayType.mon),
    ("매주 화요일 저녁 7–9시 도서관에서 스터디", .tue),
    ("Study group every Wednesday 7 to 9pm", .wed),
    ("Gym on Thursdays at 6pm", .thu),
    ("Fri 10am club meeting", .fri),
    ("Band practice Sat 2pm", .sat),
  ])
  func namedDays(text: String, day: DayType) {
    #expect(ActivityDescriptionScanner.day(in: text, today: .sun) == day)
  }

  @Test func relativeDaysCountFromToday() {
    #expect(ActivityDescriptionScanner.day(in: "오늘 저녁 운동", today: .sun) == .sun)
    #expect(ActivityDescriptionScanner.day(in: "Coffee tomorrow at 3pm", today: .sun) == .mon)
    #expect(ActivityDescriptionScanner.day(in: "내일 스터디", today: .fri) == .sat)
  }

  @Test func theFirstDayNamedWins() {
    #expect(ActivityDescriptionScanner.day(in: "화요일이랑 목요일 스터디", today: .sun) == .tue)
  }

  @Test func wordsThatOnlyLookLikeDaysAreIgnored() {
    #expect(ActivityDescriptionScanner.day(in: "I sat in the sun for a month", today: .mon) == nil)
    #expect(ActivityDescriptionScanner.day(in: "SPARCS 정모", today: .mon) == nil)
  }

  // MARK: Times

  @Test func koreanHourRange() {
    #expect(times("월요일 21-22시 동안 SPARCS 정모") == [21 * 60, 22 * 60])
    #expect(times("21시부터 22시까지") == [21 * 60, 22 * 60])
    #expect(times("19:30~21:00 스터디") == [19 * 60 + 30, 21 * 60])
  }

  @Test func koreanMeridiems() {
    #expect(times("매주 화요일 저녁 7–9시 도서관에서 스터디") == [19 * 60, 21 * 60])
    #expect(times("오후 9시-10시") == [21 * 60, 22 * 60])
    #expect(times("오전 10시 반 회의") == [10 * 60 + 30, nil])
    #expect(times("오후 3시 30분부터 5시") == [15 * 60 + 30, 17 * 60])
  }

  @Test func englishMeridiems() {
    #expect(times("9 PM to 10 PM") == [21 * 60, 22 * 60])
    #expect(times("Study group 7 to 9pm") == [19 * 60, 21 * 60])
    #expect(times("11am-1pm lunch") == [11 * 60, 13 * 60])
    #expect(times("12-1pm") == [12 * 60, 13 * 60])
    #expect(times("Gym at 6pm") == [18 * 60, nil])
  }

  @Test func earlyBareHoursAreAfternoon() {
    #expect(times("1-3시 동아리") == [13 * 60, 15 * 60])
    #expect(times("3시 커피") == [15 * 60, nil])
    #expect(times("10-11시 스터디") == [10 * 60, 11 * 60])
  }

  @Test func numbersThatAreNotTimesAreIgnored() {
    #expect(times("E11 412호에서 스터디") == nil)
    #expect(times("SPARCS 정모 with 3 people") == nil)
    #expect(times("Room E11 at 7pm") == [19 * 60, nil])
  }
}
