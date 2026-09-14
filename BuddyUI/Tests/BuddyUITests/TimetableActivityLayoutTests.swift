import Testing
import Foundation
import BuddyDomain
@testable import TimetableUI
import BuddyUpcomingClassWidgetUI

struct TimetableActivityLayoutTests {
  @Test func activitiesExpandBoundsAndWeekendColumnsWithoutCredits() {
    let activity = TimetableActivity(id: 17, title: "Study", location: "Library", day: .sat, begin: 420, end: 1350)
    let table = Timetable(id: "1", lectures: [], activities: [activity])
    let layout = TimetableLayout(classes: [], activities: table.activities, placement: .widget)
    #expect(layout.startMinutes == 420)
    #expect(layout.endMinutes == 1380)
    #expect(table.visibleDays.contains(.sat))
    #expect(!table.visibleDays.contains(.sun))
    #expect(table.credits == 0)
    #expect(table.creditAUs == 0)
  }

  @Test func conflictAllowsTouchingAndExcludesEditedActivity() {
    let activity = TimetableActivity(id: 17, title: "Study", location: "Library", day: .mon, begin: 660, end: 720)
    let table = Timetable(id: "1", lectures: [], activities: [activity])
    #expect(activity.draft.hasConflict(in: table))
    #expect(!activity.draft.hasConflict(in: table, excluding: 17))
    #expect(!TimetableActivityDraft(title: "Next", location: "", day: .mon, begin: 720, end: 780).hasConflict(in: table))
    #expect(TimetableActivityDraft(title: "Next", location: "", day: .mon, begin: 675, end: 690).hasConflict(in: table))
    #expect(!TimetableActivityDraft(title: "", location: "", day: .mon, begin: 720, end: 780).isValid)
    #expect(!TimetableActivityDraft(title: "Next", location: "", day: .mon, begin: 1380, end: 1500).isValid)
  }

  @Test func widgetShowsOngoingActivityAndClearsAtItsEnd() {
    let now = Calendar.current.startOfDay(for: .now).addingTimeInterval(11 * 3600)
    let activity = TimetableActivity(id: 17, title: "Study", location: "Library", day: DayType.from(date: now), begin: 630, end: 720)
    let entries = TimetableEventTimeline.entries(for: Timetable(id: "1", lectures: [], activities: [activity]), now: now)
    #expect(entries.first?.title == "Study")
    #expect(entries.first?.location == "Library")
    #expect(entries.first?.lecture == nil)
    #expect(entries.first?.activity?.id == 17)
    let end = Calendar.current.startOfDay(for: now).addingTimeInterval(12 * 3600)
    #expect(entries.first(where: { $0.date == end })?.title == nil)
  }
}
