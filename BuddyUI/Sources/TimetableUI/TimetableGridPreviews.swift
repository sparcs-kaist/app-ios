#if DEBUG
import SwiftUI
import BuddyDomain

#Preview("iPhone", traits: .fixedLayout(width: 370, height: 500)) {
  TimetableGrid(selectedTimetable: .mock, placement: .view)
    .padding()
}

#Preview("iPad", traits: .fixedLayout(width: 600, height: 750)) {
  TimetableGrid(selectedTimetable: .mock, placement: .view)
    .padding()
}

#Preview("Widget", traits: .fixedLayout(width: 330, height: 330)) {
  TimetableGrid(selectedTimetable: .mock, placement: .widget)
    .padding()
}

#Preview("Empty", traits: .fixedLayout(width: 370, height: 500)) {
  TimetableGrid(selectedTimetable: nil, placement: .view)
    .padding()
}

#Preview("Custom time range", traits: .fixedLayout(width: 370, height: 500)) {
  TimetableGrid(selectedTimetable: .mock, beginTime: 480, endTime: 1320, placement: .view)
    .padding()
}

#Preview("Two overlapping classes", traits: .fixedLayout(width: 370, height: 500)) {
  TimetableGrid(selectedTimetable: overlapPreviewTable(count: 2), placement: .view)
    .padding()
}

#Preview("Three overlapping classes", traits: .fixedLayout(width: 370, height: 500)) {
  TimetableGrid(selectedTimetable: overlapPreviewTable(count: 3), placement: .view)
    .padding()
}

#Preview("Widget overlaps, dark", traits: .fixedLayout(width: 330, height: 330)) {
  TimetableGrid(selectedTimetable: overlapPreviewTable(count: 2), placement: .widget)
    .padding()
    .preferredColorScheme(.dark)
}

private func overlapPreviewTable(count: Int) -> Timetable {
  let lectures = (0..<count).map { index in
    let source = Lecture.mock
    return Lecture(
      id: source.id + index,
      courseID: source.courseID + index,
      section: source.section,
      name: ["System Programming", "Linear Algebra", "Physics"][index],
      subtitle: source.subtitle,
      code: source.code,
      department: source.department,
      type: source.type,
      capacity: source.capacity,
      enrolledCount: source.enrolledCount,
      credit: source.credit,
      creditAU: source.creditAU,
      grade: source.grade,
      load: source.load,
      speech: source.speech,
      isEnglish: source.isEnglish,
      professors: source.professors,
      classes: [LectureClass(
        day: .mon, begin: 540 + index * 15, end: 660 + index * 15,
        buildingCode: "E11", buildingName: "Creative Learning B/D", roomName: "304"
      ), LectureClass(
        day: .wed, begin: 540 + index * 120, end: 630 + index * 120,
        buildingCode: "E11", buildingName: "Creative Learning B/D", roomName: "304"
      )],
      exams: [],
      classDuration: source.classDuration,
      expDuration: source.expDuration
    )
  }
  return Timetable(id: "overlap-preview", lectures: lectures)
}
#endif
