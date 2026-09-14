import Foundation
import BuddyDomain
import WidgetKit

/// Builds entries for lectures and custom activities, including ongoing events
/// and their end boundaries so an activity never remains after it has finished.
public enum TimetableEventTimeline {
  public static func entries(for timetable: Timetable, now: Date = .now) -> [LectureEntry] {
    let calendar = Calendar.current
    let day = DayType.from(date: now, calendar: calendar)
    let lectures = timetable.lectureItems(for: now)
    let activities = timetable.activities.filter { $0.day == day && $0.duration > 0 }
    var events: [(begin: Int, end: Int, entry: (Date, Date) -> LectureEntry)] = lectures.map { item in
      (item.lectureClass.begin, item.lectureClass.end, { date, start in
        LectureEntry(date: date, lecture: item.lecture, lectureClass: item.lectureClass,
          startDate: start, signInRequired: false, backgroundColor: item.lecture.backgroundColor, relevance: .init(score: 80))
      })
    }
    events += activities.map { activity in
      (activity.begin, activity.end, { date, start in
        LectureEntry(date: date, lecture: nil, lectureClass: nil, startDate: start,
          signInRequired: false, backgroundColor: activity.backgroundColor, relevance: .init(score: 80), activity: activity)
      })
    }
    events.sort { $0.begin < $1.begin }
    let midnight = calendar.startOfDay(for: now)
    func date(_ minute: Int) -> Date { calendar.date(byAdding: .minute, value: minute, to: midnight) ?? now }
    let nextDay = calendar.date(byAdding: .day, value: 1, to: midnight) ?? now.addingTimeInterval(86400)
    var boundaries: Set<Date> = [now, nextDay]
    for event in events {
      for boundary in [date(event.begin - 30), date(event.begin), date(event.end)] where boundary > now {
        boundaries.insert(boundary)
      }
    }
    return boundaries.sorted().map { boundary in
      if boundary < nextDay,
         let event = events.first(where: { date($0.end) > boundary && date($0.begin - 30) <= boundary }) {
        return event.entry(boundary, date(event.begin))
      }
      return LectureEntry(date: boundary, lecture: nil, lectureClass: nil, startDate: nil,
        signInRequired: false, backgroundColor: .black, relevance: .init(score: 10))
    }
  }
}
