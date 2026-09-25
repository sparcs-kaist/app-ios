//
//  CreditCalculationView.swift
//  BuddyFeature
//
//  Created by Soongyu Kwon on 9/25/26.
//

import SwiftUI
import BuddyDomain
import TimetableUI

struct CreditCalculationView: View {
	@State private var viewModel: CreditCalculationViewModel
	@State private var selectedSemester: TakenSemester?
	@Namespace private var transitionNamespace

	private let columns = Array(repeating: GridItem(.flexible(), spacing: 16), count: 2)

	private static let cardPadding: CGFloat = 8
	/// Concentric with the silhouette's 4pt day columns: inner radius + padding.
	private static let cardCornerRadius: CGFloat = 4 + cardPadding

	init(viewModel: CreditCalculationViewModel = CreditCalculationViewModel()) {
		self._viewModel = State(initialValue: viewModel)
	}

	var body: some View {
		content
			.navigationTitle(String(localized: "Credits", bundle: .module))
			// Item-based: this screen is itself pushed by a destination NavigationLink,
			// and a value-based link here would be resolved beneath it.
			.navigationDestination(item: $selectedSemester) { item in
				GradeEntryView(item: item, viewModel: viewModel)
					.navigationTransition(.zoom(sourceID: item.id, in: transitionNamespace))
			}
			.task { await viewModel.load() }
	}

	@ViewBuilder
	private var content: some View {
		switch viewModel.state {
		case .loading:
			ProgressView()
				.frame(maxWidth: .infinity, maxHeight: .infinity)
		case .error(let message):
			ContentUnavailableView {
				Label(String(localized: "Error", bundle: .module), systemImage: "exclamationmark.triangle")
			} description: {
				Text(message)
			} actions: {
				Button(String(localized: "Retry", bundle: .module)) {
					Task { await viewModel.load() }
				}
			}
		case .loaded:
			ScrollView {
				LazyVGrid(columns: columns, spacing: 16) {
					ForEach(viewModel.semesters) { item in
						semesterCell(item)
					}
				}
				.padding()
				.contentWidth()
			}
		}
	}

	private func semesterCell(_ item: TakenSemester) -> some View {
		let timetable = viewModel.timetables[item.id]
		let summary = viewModel.summary(for: item)

		return Button {
			selectedSemester = item
		} label: {
			VStack(alignment: .leading, spacing: 8) {
				HStack(spacing: 4) {
					Text(item.title)
				
					Image(systemName: "chevron.right")
						.foregroundStyle(.tertiary)

					Spacer(minLength: 0)

					if let summary, !summary.isComplete {
						Image(systemName: "exclamationmark.circle.fill")
							.foregroundStyle(.orange)
							.accessibilityLabel(String(localized: "Grades incomplete", bundle: .module))
					}
				}
				.font(.subheadline)
				.fontWeight(.semibold)

				TimetableSilhouetteView(timetable: timetable)
					.aspectRatio(1, contentMode: .fit)

				HStack(spacing: 4) {
					Text(String(localized: "\(gpaText(summary?.gpa)) GPA", bundle: .module))

					Spacer()

					Text(String(localized: "\(timetable?.credits ?? 0) CR", bundle: .module))
					if let creditAUs = timetable?.creditAUs, creditAUs > 0 {
						Text(String(localized: "\(creditAUs) AU", bundle: .module))
							.foregroundStyle(.secondary)
					}
				}
				.textCase(.uppercase)
				.font(.footnote)
				// Placeholder until the semester's table arrives.
				.redacted(reason: timetable == nil ? .placeholder : [])
			}
			.padding(Self.cardPadding)
			.background(Color(uiColor: .secondarySystemBackground), in: .rect(cornerRadius: Self.cardCornerRadius))
			.contentShape(.rect(cornerRadius: Self.cardCornerRadius))
		}
		.buttonStyle(.plain)
		.accessibilityHint(String(localized: "Enter grades", bundle: .module))
		.disabled(timetable == nil)
		// Zoom from the whole card, keeping its rounded corners during the transition.
		.matchedTransitionSource(id: item.id, in: transitionNamespace) { source in
			source.clipShape(.rect(cornerRadius: Self.cardCornerRadius))
		}
		.task { await viewModel.loadTimetable(for: item) }
	}

	/// Two decimals, or a dash until a grade that counts toward GPA is entered.
	private func gpaText(_ gpa: Double?) -> String {
		gpa?.formatted(.number.precision(.fractionLength(2))) ?? "–"
	}
}


#Preview {
	let timetables = Timetable.mockList
	let semesters = [
		TakenSemester(id: "2024-Spring", title: "2024 Spring", semester: nil),
		TakenSemester(id: "2024-Autumn", title: "2024 Autumn", semester: nil),
		TakenSemester(id: "2025-Spring", title: "2025 Spring", semester: nil),
		TakenSemester(id: "2025-Autumn", title: "2025 Autumn", semester: nil),
		TakenSemester(id: "2026-Spring", title: "2026 Spring", semester: nil)
	]

	NavigationStack {
		CreditCalculationView(viewModel: CreditCalculationViewModel(
			semesters: semesters,
			timetables: [
				"2024-Spring": .mock,
				"2024-Autumn": timetables[1],
				"2025-Spring": timetables[0],
				"2025-Autumn": timetables[0],
				"2026-Spring": timetables[2]
			],
			// 2024 Spring fully graded; 2025 Spring partially, so it shows the indicator.
			grades: Dictionary(
				Timetable.mock.lectures.map { ($0.id, LectureGrade.aMinus) }
					+ timetables[0].lectures.prefix(2).map { ($0.id, LectureGrade.aPlus) },
				uniquingKeysWith: { first, _ in first }
			)
		))
	}
}
