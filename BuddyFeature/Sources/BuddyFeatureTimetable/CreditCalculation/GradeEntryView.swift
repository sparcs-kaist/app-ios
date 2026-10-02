//
//  GradeEntryView.swift
//  BuddyFeature
//
//  Created by Soongyu Kwon on 25/09/2026.
//

import SwiftUI
import BuddyDomain
import TimetableUI

/// A semester's timetable with a grade picker for each of its lectures.
struct GradeEntryView: View {
	let item: TakenSemester
	let viewModel: CreditCalculationViewModel

	@State private var size: CGSize = .zero

	/// Like the Timetable screen: 80% of the height, never squashed below 500pt.
	private static let minimumGridHeight: CGFloat = 500

	var body: some View {
		let timetable = viewModel.timetables[item.id]
		let lectures = timetable?.lectures ?? []
		let gridHeight = max(size.height * 0.8, Self.minimumGridHeight)

		ScrollView {
			Group {
				if CreditLayout.isWide(size.width) {
					// Side by side on wide screens, like the Timetable screen.
					HStack(alignment: .top, spacing: 20) {
						GradeEntryGridCard(timetable: timetable, height: gridHeight)
							.frame(maxWidth: .infinity)
						if !lectures.isEmpty {
							GradeEntryLectureList(lectures: lectures, retakenIDs: viewModel.supersededLectureIDs, grade: gradeBinding)
								.frame(maxWidth: .infinity)
						}
					}
				} else {
					VStack(spacing: 20) {
						GradeEntryGridCard(timetable: timetable, height: gridHeight)
						if !lectures.isEmpty {
							GradeEntryLectureList(lectures: lectures, retakenIDs: viewModel.supersededLectureIDs, grade: gradeBinding)
						}
					}
				}
			}
			.padding()
			.creditContentWidth()
		}
		.onGeometryChange(for: CGSize.self) { $0.size } action: { size = $0 }
		// Same backdrop as the Timetable screen, so the white cards stand out.
		.background(Color.systemGroupedBackground)
		.navigationTitle(item.title)
		// Updates live as grades are picked below.
		.navigationSubtitle(String(localized: "\(formattedGPA(viewModel.summary(for: item)?.gpa))/4.3 GPA", bundle: .module))
		.toolbarTitleDisplayMode(.inline)
	}

	/// Reads and writes one lecture's grade through the view model, which persists it.
	private func gradeBinding(for lecture: Lecture) -> Binding<LectureGrade?> {
		let lectureID = lecture.id
		return Binding(
			get: { viewModel.grades[lectureID] },
			set: { viewModel.setGrade($0, lectureID: lectureID) }
		)
	}
}

/// The semester's timetable grid in the Timetable screen's grid card.
private struct GradeEntryGridCard: View {
	let timetable: Timetable?
	let height: CGFloat

	var body: some View {
		ThemedGridCard {
			TimetableGrid(selectedTimetable: timetable, placement: .view)
		}
		.frame(height: height)
	}
}

/// Mirrors the Timetable screen's LectureList, with a grade picker per row.
private struct GradeEntryLectureList: View {
	let lectures: [Lecture]
	/// Lectures replaced by a later or better attempt of the same course.
	let retakenIDs: Set<Int>
	/// Each lecture's grade, bound to where it's stored.
	let grade: (Lecture) -> Binding<LectureGrade?>

	var body: some View {
		VStack(alignment: .leading) {
			Text("\(lectures.count) Lectures", bundle: .module)
				.font(.title3)
				.fontWeight(.bold)

			ForEach(lectures) { lecture in
				HStack {
					LectureListRow(
						lecture: lecture,
						detail: .grading,
						badge: retakenIDs.contains(lecture.id) ? String(localized: "Retaken", bundle: .module) : nil
					)
					GradeMenu(lecture: lecture, grade: grade(lecture))
				}

				if lecture.id != lectures.last?.id {
					Divider()
						.padding(.leading, 20)
				}
			}

			if lectures.contains(where: { retakenIDs.contains($0.id) }) {
				Text("Retaken lectures don't count toward your cumulative GPA and credits.", bundle: .module)
					.font(.footnote)
					.foregroundStyle(.secondary)
					.padding(.top, 8)
			}
		}
		.timetableCardStyle()
	}
}

/// One lecture's grade: a compact button that opens the grades it can take.
private struct GradeMenu: View {
	let lecture: Lecture
	/// `nil` when ungraded; setting `nil` clears the grade.
	@Binding var grade: LectureGrade?

	var body: some View {
		Menu {
			// First, so it's visible without scrolling the long credit-grade list.
			if grade != nil {
				Button(String(localized: "Clear Grade", bundle: .module), systemImage: "xmark", role: .destructive) {
					grade = nil
				}
			}

			Picker(String(localized: "Grade", bundle: .module), selection: $grade) {
				ForEach(LectureGrade.options(for: lecture), id: \.self) { option in
					Text(option.menuTitle).tag(Optional(option))
				}
			}
			.pickerStyle(.inline)
		} label: {
			// Ungraded rows stand out so an incomplete semester is easy to finish.
			// Coloured here, not with `.tint` on the Menu: that tint would also
			// recolour the menu's items, including Clear Grade's destructive red.
			let color: Color = grade == nil ? .orange : .accentColor
			// Compact, so the row's caption keeps its room.
			Text(grade?.title ?? "–")
				.fontWeight(.semibold)
				.frame(minWidth: 28)
				.padding(.horizontal, 8)
				.padding(.vertical, 7)
				.foregroundStyle(color)
				.background(color.opacity(0.15), in: .capsule)
		}
		.accessibilityLabel(String(localized: "Grade for \(lecture.name)", bundle: .module))
	}
}

private extension LectureGrade {
	/// Menu text: spells out the non-letter grades.
	var menuTitle: String {
		switch self {
		case .pass: String(localized: "P (Pass)", bundle: .module)
		case .fail: String(localized: "F (Fail)", bundle: .module)
		case .nonRecord: String(localized: "NR (Non-record)", bundle: .module)
		case .satisfied: String(localized: "S (Satisfied)", bundle: .module)
		case .unsatisfied: String(localized: "U (Unsatisfied)", bundle: .module)
		default: title
		}
	}
}

#Preview {
	let item = TakenSemester(id: "2025-Autumn", title: "2025 Autumn", semester: nil)
	let timetable = Timetable.mockList[0]

	NavigationStack {
		GradeEntryView(
			item: item,
			viewModel: CreditCalculationViewModel(
				semesters: [item],
				timetables: [item.id: timetable],
				grades: timetable.lectures.first.map { [$0.id: .aPlus] } ?? [:]
			)
		)
	}
}
