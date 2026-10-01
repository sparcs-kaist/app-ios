//
//  CourseHistorySection.swift
//  BuddyFeature
//
//  Created by Soongyu Kwon on 01/10/2026.
//

import SwiftUI
import BuddyDomain

/// Every semester a course was offered, newest first, with each section's professors.
/// When a professor is selected their sections are highlighted and the rest recede.
struct CourseHistorySection: View {
  let history: [CourseHistory]
  let selectedProfessorID: Int?
  let onSelectProfessor: (Int?) -> Void

  @State private var scrolledID: String?

  var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      HStack(alignment: .firstTextBaseline) {
        Text("History", bundle: .module)
          .font(.title3)
          .fontWeight(.bold)
        Spacer()
        Text("Offered \(history.count) times", bundle: .module)
          .font(.footnote)
          .foregroundStyle(.secondary)
      }

      ScrollView(.horizontal) {
        // Not lazy: a course has a few dozen offerings at most, and the fixed
        // vertical size lets every card stretch to the tallest one.
        HStack(alignment: .top, spacing: 12) {
          ForEach(history, id: \.id) { entry in
            semesterCard(entry)
              .id(entry.id)
          }
        }
        .fixedSize(horizontal: false, vertical: true)
        .scrollTargetLayout()
      }
      .scrollIndicators(.hidden)
      .scrollClipDisabled()
      .scrollTargetBehavior(.viewAligned)
      .scrollPosition(id: $scrolledID, anchor: .leading)
      .onChange(of: selectedProfessorID) { _, id in
        // Bring the professor's most recent offering into view.
        guard let id, let match = history.first(where: { isTaught(by: id, in: $0) }) else { return }
        withAnimation(.smooth) { scrolledID = match.id }
      }
    }
  }

  private func semesterCard(_ entry: CourseHistory) -> some View {
    let isDimmed = selectedProfessorID.map { !isTaught(by: $0, in: entry) } ?? false

    return VStack(alignment: .leading, spacing: 10) {
      HStack {
        Text(verbatim: "\(entry.year) \(entry.semester.description)")
          .font(.subheadline)
          .fontWeight(.semibold)
        Spacer(minLength: 4)
        if entry.myLectureID != nil {
          Image(systemName: "checkmark.circle.fill")
            .foregroundStyle(.tint)
            .accessibilityLabel(String(localized: "Taken", bundle: .module))
        }
      }

      VStack(alignment: .leading, spacing: 6) {
        ForEach(entry.classes, id: \.lectureID) { lectureClass in
          classRow(lectureClass)
        }
      }
    }
    .padding(14)
    .frame(width: 168, alignment: .topLeading)
    .frame(maxHeight: .infinity, alignment: .top)
    .background(.fill.quaternary, in: .rect(cornerRadius: 20))
    .opacity(isDimmed ? 0.45 : 1)
    .animation(.smooth, value: isDimmed)
    .accessibilityElement(children: .contain)
  }

  private func classRow(_ lectureClass: CourseHistoryClass) -> some View {
    let isMatch = selectedProfessorID.map { id in lectureClass.professors.contains { $0.id == id } } ?? false
    let names = lectureClass.professors.map(\.name)
    let professorID = lectureClass.professors.first?.id

    return Button {
      // Tapping a section is a shortcut for picking its professor; tapping again clears it.
      onSelectProfessor(isMatch ? nil : professorID)
    } label: {
      HStack(alignment: .firstTextBaseline, spacing: 6) {
        if !lectureClass.section.isEmpty {
          Text(lectureClass.section)
            .fontDesign(.rounded)
            .foregroundStyle(.secondary)
            .frame(minWidth: 14, alignment: .leading)
        }
        Text(names.isEmpty ? String(localized: "Unknown", bundle: .module) : names.formatted(.list(type: .and, width: .narrow)))
          .fontWeight(isMatch ? .semibold : .regular)
          .foregroundStyle(isMatch ? AnyShapeStyle(.tint) : AnyShapeStyle(.primary))
          .lineLimit(2)
          .multilineTextAlignment(.leading)
      }
      .font(.footnote)
      .frame(maxWidth: .infinity, alignment: .leading)
      .contentShape(.rect)
    }
    .buttonStyle(.plain)
    .disabled(professorID == nil)
    .accessibilityHint(String(localized: "Shows this professor's reviews", bundle: .module))
  }

  private func isTaught(by professorID: Int, in entry: CourseHistory) -> Bool {
    entry.classes.contains { $0.professors.contains { $0.id == professorID } }
  }

  /// Stand-in offerings shaped like real ones, redacted while the course loads.
  static let placeholder: [CourseHistory] = [
    (2026, SemesterType.autumn, 2),
    (2026, .spring, 1),
    (2025, .autumn, 2)
  ].map { year, semester, sections in
    CourseHistory(
      year: year,
      semester: semester,
      classes: (0..<sections).map { index in
        CourseHistoryClass(
          lectureID: -(year * 10 + semester.intValue) * 10 - index,
          subtitle: "",
          section: String(UnicodeScalar(UInt8(65 + index))),
          professors: [Professor(id: -index - 1, name: "Professor Name")]
        )
      },
      myLectureID: nil
    )
  }
}

private extension CourseHistory {
  var id: String { "\(year)-\(semester.intValue)" }
}
