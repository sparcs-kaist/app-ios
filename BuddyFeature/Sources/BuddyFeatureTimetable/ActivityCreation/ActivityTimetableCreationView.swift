import SwiftUI
import BuddyDomain
import TimetableUI

struct ActivityTimetableCreationView: View {
  let timetable: Timetable?
  let title: String
  let occupiedTimes: [TimetableTimeSelection]
  @Binding private var time: TimetableTimeSelection
  @State private var draft: TimetableTimeSelection

  init(timetable: Timetable?, title: String, time: Binding<TimetableTimeSelection>, occupiedTimes: [TimetableTimeSelection] = []) {
    self.timetable = timetable
    self.title = title
    self.occupiedTimes = occupiedTimes
    self._time = time
    self._draft = State(initialValue: time.wrappedValue)
  }

  private var hasConflict: Bool {
    !draft.conflictingLectures(in: timetable).isEmpty || !draft.conflictingActivities(in: timetable).isEmpty || occupiedTimes.contains(where: draft.overlaps)
  }

  var body: some View {
    TimetableTimePicker(timetable: timetable, title: title, selection: $draft, occupiedTimes: occupiedTimes)
      .overlay(alignment: .bottom) {
        VStack {
          if hasConflict || timetable == nil {
            ActivityTimeConflictView(time: draft, timetable: timetable, occupiedTimes: occupiedTimes)
              .accessibilityIdentifier("activity.conflictStatus")
              .padding(14)
              .frame(maxWidth: .infinity, alignment: .leading)
              .glassEffect(.regular.interactive(), in: .capsule)
              .padding()
              .allowsHitTesting(false)
              .transition(.move(edge: .bottom).combined(with: .opacity))
          }
        }
        .animation(.spring(response: 0.35, dampingFraction: 0.8), value: hasConflict)
      }
      .navigationTitle(Text("Adjust Time", bundle: .module))
      .navigationBarTitleDisplayMode(.inline)
      .onChange(of: draft) { _, updated in
        // Keep conflicting positions visible while editing, but only carry free
        // times back to the form, including when using the native back gesture.
        guard timetable != nil, !hasConflict else { return }
        time = updated
      }
  }
}

/// The manual form and timetable editor use the same conflict rule and feedback.
struct ActivityTimeConflictView: View {
  let time: TimetableTimeSelection
  let timetable: Timetable?
  var occupiedTimes: [TimetableTimeSelection] = []

  var body: some View {
    let conflicts = time.conflictingLectures(in: timetable)
    if timetable == nil {
      Label(String(localized: "Load a timetable to check for conflicts.", bundle: .module), systemImage: "info.circle")
        .font(.footnote)
        .foregroundStyle(.secondary)
    } else if let lecture = conflicts.first {
      Label {
        Text("Overlaps with \(lecture.name). Choose a free time.", bundle: .module)
      } icon: {
        Image(systemName: "exclamationmark.triangle.fill")
      }
      .font(.footnote)
      .foregroundStyle(.red)
      .accessibilityAddTraits(.updatesFrequently)
    } else if !time.conflictingActivities(in: timetable).isEmpty || occupiedTimes.contains(where: time.overlaps) {
      Label(String(localized: "Overlaps another activity. Choose a free time.", bundle: .module), systemImage: "exclamationmark.triangle.fill")
        .font(.footnote)
        .foregroundStyle(.red)
        .accessibilityAddTraits(.updatesFrequently)
    } else {
      Label(String(localized: "Activities can’t overlap classes or other activities.", bundle: .module), systemImage: "checkmark.shield")
        .font(.footnote)
        .foregroundStyle(.secondary)
    }
  }
}

#Preview("Adjust activity time") {
  @Previewable @State var time = TimetableTimeSelection(day: .mon, begin: 660, end: 720)
  NavigationStack {
    ActivityTimetableCreationView(timetable: .mock, title: "Study group", time: $time)
  }
}

#Preview("Conflicting activity") {
  @Previewable @State var time = TimetableTimeSelection(day: .mon, begin: 540, end: 600)
  NavigationStack {
    ActivityTimetableCreationView(timetable: .mock, title: "Study group", time: $time)
  }
}
