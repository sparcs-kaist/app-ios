//
//  LectureReplacement.swift
//  BuddyFeature
//

import SwiftUI
import BuddyDomain

/// Adds a lecture. `replacingConflicts` is set once the user has agreed to replace whatever the
/// lecture overlaps in the timetable.
typealias AddLectureAction = (_ lecture: Lecture, _ replacingConflicts: Bool) -> Void

/// The question asked before adding a lecture that overlaps others, in every place one can be
/// added, so the wording stays the same.
enum LectureReplacement {
  static var title: String {
    String(localized: "Replace Overlapping Items?", bundle: .module)
  }

  static func message(conflicts: [String]) -> String {
    let list = conflicts.formatted(.list(type: .and))
    return String(localized: "This lecture overlaps with \(list) in your timetable. Remove them and add this lecture instead?", bundle: .module)
  }

  static var confirm: String {
    String(localized: "Replace", bundle: .module)
  }

  static var cancel: String {
    String(localized: "Cancel", bundle: .module)
  }
}

extension View {
  /// Asks whether to replace what `lecture` overlaps, while `lecture` is set.
  func lectureReplacementAlert(
    for lecture: Binding<Lecture?>,
    conflicts: @escaping (Lecture) -> [String],
    onReplace: @escaping (Lecture) -> Void
  ) -> some View {
    alert(
      LectureReplacement.title,
      isPresented: Binding(
        get: { lecture.wrappedValue != nil },
        set: { if !$0 { lecture.wrappedValue = nil } }
      ),
      presenting: lecture.wrappedValue
    ) { lecture in
      Button(LectureReplacement.confirm, role: .destructive) { onReplace(lecture) }
      Button(LectureReplacement.cancel, role: .cancel) { }
    } message: { lecture in
      Text(LectureReplacement.message(conflicts: conflicts(lecture)))
    }
  }
}
