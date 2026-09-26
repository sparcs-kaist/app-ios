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
	@State private var showsRequirements = false
	@Namespace private var transitionNamespace

	private let columns = Array(repeating: GridItem(.flexible(), spacing: 16), count: 2)

	/// Stand-in cards for the skeleton while the semester list loads.
	private static let placeholderSemesters = (0..<6).map {
		TakenSemester(id: "placeholder-\($0)", title: "2026 Spring", semester: nil)
	}

	private static let cardPadding: CGFloat = 8
	/// Concentric with the silhouette's 4pt day columns: inner radius + padding.
	private static let cardCornerRadius: CGFloat = 4 + cardPadding

	init(viewModel: CreditCalculationViewModel = CreditCalculationViewModel()) {
		self._viewModel = State(initialValue: viewModel)
	}

	var body: some View {
		content
			.navigationTitle(String(localized: "Credits", bundle: .module))
			.navigationSubtitle(semesterCountText)
			// Explicit, like the Timetable screen; otherwise it changes after a push and pop.
			.toolbarTitleDisplayMode(.inlineLarge)
			// Item-based: this screen is itself pushed by a destination NavigationLink,
			// and a value-based link here would be resolved beneath it.
			.navigationDestination(item: $selectedSemester) { item in
				GradeEntryView(item: item, viewModel: viewModel)
					.navigationTransition(.zoom(sourceID: item.id, in: transitionNamespace))
			}
			.navigationDestination(isPresented: $showsRequirements) {
				CreditRequirementsView(viewModel: viewModel)
					.navigationTransition(.zoom(sourceID: Self.requirementsTransitionID, in: transitionNamespace))
			}
			.task { await viewModel.load() }
	}

	@ViewBuilder
	private var content: some View {
		switch viewModel.state {
		case .loading:
			// Real cards without timetables: grey day columns and redacted text.
			semesterGrid(Self.placeholderSemesters)
				.redacted(reason: .placeholder)
				.disabled(true)
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
			semesterGrid(viewModel.semesters)
		}
	}

	private func semesterGrid(_ semesters: [TakenSemester]) -> some View {
		ScrollView {
			VStack(alignment: .leading, spacing: 28) {
				VStack(alignment: .leading, spacing: 12) {
					sectionHeader(String(localized: "Summary", bundle: .module))
					gpaTrendCard
					summaryCard

					Text("GPA and credits are estimates based on the grades you enter, and are for your reference only. Confirm your graduation requirements with KAIST's official academic records.", bundle: .module)
						.font(.footnote)
						.foregroundStyle(.secondary)
						.padding(.horizontal, 4)
				}

				VStack(alignment: .leading, spacing: 12) {
					sectionHeader(String(localized: "Semesters", bundle: .module))
					LazyVGrid(columns: columns, spacing: 16) {
						ForEach(semesters) { item in
							semesterCell(item)
						}
					}
				}
			}
			.padding()
			.contentWidth()
		}
	}

	/// Matches the Timetable screen's section titles, e.g. its lecture list's.
	private func sectionHeader(_ title: String) -> some View {
		Text(title)
			.font(.title3)
			.fontWeight(.bold)
			.accessibilityAddTraits(.isHeader)
	}

	private static let trendChartHeight: CGFloat = 160

	private var gpaTrendCard: some View {
		let points = viewModel.gpaTrend

		return VStack(alignment: .leading, spacing: 12) {
			Text("GPA by Semester", bundle: .module)
				.font(.subheadline)
				.foregroundStyle(.secondary)

			if !viewModel.isOverallSummaryReady {
				// Charts aren't redacted; stand in with a plain block while loading.
				RoundedRectangle(cornerRadius: Self.cardCornerRadius)
					.fill(.quaternary)
					.frame(height: Self.trendChartHeight)
			} else if points.isEmpty {
				Text("Enter grades to see your GPA by semester.", bundle: .module)
					.font(.footnote)
					.foregroundStyle(.secondary)
					.frame(maxWidth: .infinity, minHeight: Self.trendChartHeight)
			} else {
				GPATrendChart(points: points)
					.frame(height: Self.trendChartHeight)
			}
		}
		.padding(Self.cardPadding * 2)
		.background(Color(uiColor: .secondarySystemBackground), in: .rect(cornerRadius: Self.cardCornerRadius + Self.cardPadding))
	}

	private static let requirementsTransitionID = "credit-requirements"

	private var summaryCard: some View {
		let summary = viewModel.overallSummary
		let earned = summary.earnedCredits
		let graduationCredits = viewModel.requirements.graduation
		let cornerRadius = Self.cardCornerRadius + Self.cardPadding

		return Button {
			showsRequirements = true
		} label: {
			summaryCardContent(gpa: summary.gpa, earned: earned, graduationCredits: graduationCredits)
				.padding(Self.cardPadding * 2)
				.background(Color(uiColor: .secondarySystemBackground), in: .rect(cornerRadius: cornerRadius))
				.contentShape(.rect(cornerRadius: cornerRadius))
		}
		.buttonStyle(.plain)
		.accessibilityHint(String(localized: "Shows credits by requirement", bundle: .module))
		.disabled(!viewModel.isOverallSummaryReady)
		.matchedTransitionSource(id: Self.requirementsTransitionID, in: transitionNamespace) { source in
			source.clipShape(.rect(cornerRadius: cornerRadius))
		}
		// Semesters load one by one; don't show a partial total.
		.redacted(reason: viewModel.isOverallSummaryReady ? [] : .placeholder)
	}

	private func summaryCardContent(gpa: Double?, earned: Int, graduationCredits: Int) -> some View {
		VStack(alignment: .leading, spacing: 12) {
			HStack(alignment: .firstTextBaseline) {
				summaryValue(
					title: String(localized: "GPA", bundle: .module),
					value: gpaText(gpa),
					total: "4.3",
					alignment: .leading
				)

				Spacer()

				summaryValue(
					title: String(localized: "Credits", bundle: .module),
					value: "\(earned)",
					total: "\(graduationCredits)",
					alignment: .trailing
				)

				// Opens Credit Requirements; matches the semester cards' chevron.
				Image(systemName: "chevron.right")
					.font(.subheadline)
					.fontWeight(.semibold)
					.foregroundStyle(.tertiary)
					.accessibilityHidden(true)
			}

			ProgressView(value: Double(min(earned, graduationCredits)), total: Double(max(graduationCredits, 1)))
				.progressViewStyle(ThickLinearProgressViewStyle(height: 18))
				.tint(earned >= graduationCredits ? .green : .accentColor)
				.accessibilityLabel(String(localized: "Credits towards graduation", bundle: .module))
				.accessibilityValue(String(localized: "\(earned) of \(graduationCredits) credits", bundle: .module))
		}
	}

	private func summaryValue(title: String, value: String, total: String, alignment: HorizontalAlignment) -> some View {
		VStack(alignment: alignment, spacing: 2) {
			Text(title)
				.font(.subheadline)
				.foregroundStyle(.secondary)

			HStack(alignment: .firstTextBaseline, spacing: 2) {
				Text(value)
					.font(.title2)
					.fontWeight(.bold)
					.fontDesign(.rounded)
				Text(verbatim: "/\(total)")
					.font(.subheadline)
					.foregroundStyle(.secondary)
			}
		}
		.accessibilityElement(children: .combine)
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

					// NR lectures are off the record, so their credits aren't shown.
					Text(String(localized: "\(summary?.recordedCredits ?? 0) CR", bundle: .module))
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

	private func gpaText(_ gpa: Double?) -> String { formattedGPA(gpa) }

	/// "N Semesters" once loaded; empty (no subtitle) while loading or on error.
	private var semesterCountText: String {
		guard viewModel.state == .loaded else { return "" }
		let count = viewModel.semesters.count
		return count == 1
			? String(localized: "1 Semester", bundle: .module)
			: String(localized: "\(count) Semesters", bundle: .module)
	}
}

/// Up to two decimals, dropping a trailing zero (4.30 → 4.3, 4.00 → 4.0), or a
/// dash until a grade that counts toward GPA is entered.
func formattedGPA(_ gpa: Double?) -> String {
	gpa?.formatted(.number.precision(.fractionLength(1...2))) ?? "–"
}


/// A linear progress bar with a configurable thickness; the system linear style's is fixed.
struct ThickLinearProgressViewStyle: ProgressViewStyle {
	let height: CGFloat

	func makeBody(configuration: Configuration) -> some View {
		let fraction = min(max(configuration.fractionCompleted ?? 0, 0), 1)

		Capsule()
			.fill(.quaternary)
			.overlay(alignment: .leading) {
				GeometryReader { geometry in
					Capsule()
						.fill(.tint)
						.frame(width: geometry.size.width * fraction)
				}
			}
			.clipShape(.capsule)
			.frame(height: height)
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

#Preview("Summary") {
	let item = TakenSemester(id: "2025-Spring", title: "2025 Spring", semester: nil)
	let timetable = Timetable.mockList[0]

	NavigationStack {
		CreditCalculationView(viewModel: CreditCalculationViewModel(
			semesters: [item],
			timetables: [item.id: timetable],
			grades: Dictionary(uniqueKeysWithValues: timetable.lectures.map { ($0.id, LectureGrade.aMinus) }),
			majorDepartments: timetable.lectures.first { $0.type == .mr || $0.type == .me }.map { [$0.department] } ?? []
		))
	}
}
