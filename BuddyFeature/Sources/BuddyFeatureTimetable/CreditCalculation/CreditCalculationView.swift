//
//  CreditCalculationView.swift
//  BuddyFeature
//
//  Created by Soongyu Kwon on 9/25/26.
//

import SwiftUI
import BuddyDomain
import TimetableUI
import BuddyFeatureShared

struct CreditCalculationView: View {
	@State private var viewModel: CreditCalculationViewModel
	@State private var selectedSemester: TakenSemester?
	@State private var showsRequirements = false
	@Namespace private var transitionNamespace

	/// Stand-in cards for the skeleton while the semester list loads.
	private static let placeholderSemesters = (0..<6).map {
		TakenSemester(id: "placeholder-\($0)", title: "2026 Spring", semester: nil)
	}

	init(viewModel: CreditCalculationViewModel = CreditCalculationViewModel()) {
		self._viewModel = State(initialValue: viewModel)
	}

	var body: some View {
		Group {
			switch viewModel.state {
			case .loading:
				// Real cards without timetables: grey day columns and redacted text.
				CreditsOverview(
					semesters: Self.placeholderSemesters,
					viewModel: viewModel,
					namespace: transitionNamespace,
					onSelectSemester: { _ in },
					onOpenRequirements: {}
				)
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
				CreditsOverview(
					semesters: viewModel.semesters,
					viewModel: viewModel,
					namespace: transitionNamespace,
					onSelectSemester: { selectedSemester = $0 },
					onOpenRequirements: { showsRequirements = true }
				)
			}
		}
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
				.navigationTransition(.zoom(sourceID: CreditTransitionID.requirements, in: transitionNamespace))
		}
		.task { await viewModel.load() }
	}

	/// "N Semesters" once loaded; empty (no subtitle) while loading or on error.
	private var semesterCountText: String {
		guard viewModel.state == .loaded else { return "" }
		let count = viewModel.semesters.count
		return count == 1
			? String(localized: "1 Semester", bundle: .module)
			: String(localized: "\(count) Semesters", bundle: .module)
	}
}

// MARK: - Layout

private enum CreditCardMetrics {
	static let padding: CGFloat = 8
	/// Concentric with the silhouette's 4pt day columns: inner radius + padding.
	static let cornerRadius: CGFloat = 4 + padding
	/// For the larger summary cards, which use double padding.
	static let largeCornerRadius: CGFloat = cornerRadius + padding
}

private enum CreditTransitionID {
	static let requirements = "credit-requirements"
}

/// Layout shared by the credit screens on wide widths (iPad, split view, landscape).
enum CreditLayout {
	/// Wider than `contentWidth()`'s 600pt column, so iPad uses its width for side-by-side
	/// cards and more grid columns, without stretching edge to edge.
	static let maxContentWidth: CGFloat = 1100

	/// Same threshold the Timetable screen uses for its two-column layout.
	static func isWide(_ width: CGFloat) -> Bool {
		width > LayoutMetrics.twoColumnWidthThreshold
	}
}

extension View {
	/// Caps the credit screens' content at `CreditLayout.maxContentWidth`, centred.
	func creditContentWidth() -> some View {
		frame(maxWidth: CreditLayout.maxContentWidth)
			.frame(maxWidth: .infinity)
	}
}

/// The scrolling content: the summary section and the semester grid, stacked on
/// iPhone and side by side when wide (summary left, semesters right). The only
/// subview that reads the view model; it hands each card just the values it shows.
private struct CreditsOverview: View {
	let semesters: [TakenSemester]
	let viewModel: CreditCalculationViewModel
	let namespace: Namespace.ID
	let onSelectSemester: (TakenSemester) -> Void
	let onOpenRequirements: () -> Void

	@State private var width: CGFloat = 0

	var body: some View {
		let summary = viewModel.overallSummary
		let summarySection = CreditsSummarySection(
			points: viewModel.gpaTrend,
			gpa: summary.gpa,
			earnedCredits: summary.earnedCredits,
			graduationCredits: viewModel.requirements.graduation,
			isReady: viewModel.isOverallSummaryReady,
			namespace: namespace,
			onOpenRequirements: onOpenRequirements
		)
		let semestersSection = CreditsSemestersSection(
			semesters: semesters,
			viewModel: viewModel,
			namespace: namespace,
			onSelectSemester: onSelectSemester
		)

		ScrollView {
			VStack(spacing: 28) {
				if CreditLayout.isWide(width) {
					HStack(alignment: .top, spacing: 28) {
						summarySection.frame(maxWidth: .infinity)
						semestersSection.frame(maxWidth: .infinity)
					}
				} else {
					VStack(alignment: .leading, spacing: 28) {
						summarySection
						semestersSection
					}
				}

				CreditsPrivacyFooter()
			}
			.padding()
			.creditContentWidth()
		}
		.onGeometryChange(for: CGFloat.self) { $0.size.width } action: { width = $0 }
	}
}

/// "Summary": the GPA chart, then the summary card and disclaimer.
private struct CreditsSummarySection: View {
	let points: [SemesterGPA]
	let gpa: Double?
	let earnedCredits: Int
	let graduationCredits: Int
	let isReady: Bool
	let namespace: Namespace.ID
	let onOpenRequirements: () -> Void

	var body: some View {
		VStack(alignment: .leading, spacing: 12) {
			CreditSectionHeader(title: String(localized: "Summary", bundle: .module))

			GPATrendCard(points: points, isReady: isReady)

			GPASummaryColumn(
				gpa: gpa,
				earnedCredits: earnedCredits,
				graduationCredits: graduationCredits,
				isReady: isReady,
				namespace: namespace,
				onTap: onOpenRequirements
			)
		}
	}
}

/// "Semesters": a two-column grid of semester cards, each loading its table on appear.
private struct CreditsSemestersSection: View {
	let semesters: [TakenSemester]
	/// Read per card for its table and summary, and to load tables as cards appear.
	let viewModel: CreditCalculationViewModel
	let namespace: Namespace.ID
	let onSelectSemester: (TakenSemester) -> Void

	private let columns = Array(repeating: GridItem(.flexible(), spacing: 16), count: 2)

	var body: some View {
		VStack(alignment: .leading, spacing: 12) {
			CreditSectionHeader(title: String(localized: "Semesters", bundle: .module))

			LazyVGrid(columns: columns, spacing: 16) {
				ForEach(semesters) { item in
					SemesterCard(
						item: item,
						timetable: viewModel.timetables[item.id],
						summary: viewModel.summary(for: item),
						namespace: namespace,
						onSelect: { onSelectSemester(item) }
					)
					.task { await viewModel.loadTimetable(for: item) }
				}
			}
		}
	}
}

/// The last thing on the screen: where the grades and minimums the user enters are kept.
private struct CreditsPrivacyFooter: View {
	var body: some View {
		VStack(alignment: .leading, spacing: 6) {
			HStack {
				Image(systemName: "lock.fill")
					.accessibilityHidden(true)
				
				Text("Stored on This Device", bundle: .module)
			}
			.fontWeight(.semibold)

			Text("The grades and minimum credits you enter are stored only on this device and aren't sent to Buddy or KAIST. They're kept when you sign out and deleted if you delete the app.", bundle: .module)
				.multilineTextAlignment(.leading)
		}
		.font(.footnote)
		.foregroundStyle(.secondary)
		.multilineTextAlignment(.center)
		.frame(maxWidth: 480)
		.frame(maxWidth: .infinity)
		.padding(.top, 8)
		.accessibilityElement(children: .combine)
	}
}

/// Matches the Timetable screen's section titles, e.g. its lecture list's.
private struct CreditSectionHeader: View {
	let title: String

	var body: some View {
		Text(title)
			.font(.title3)
			.fontWeight(.bold)
			.accessibilityAddTraits(.isHeader)
	}
}

// MARK: - Summary

private struct GPATrendCard: View {
	let points: [SemesterGPA]
	let isReady: Bool

	private static let chartHeight: CGFloat = 160

	var body: some View {
		VStack(alignment: .leading, spacing: 12) {
			Text("GPA by Semester", bundle: .module)
				.font(.subheadline)
				.foregroundStyle(.secondary)

			if !isReady {
				// Charts aren't redacted; stand in with a plain block while loading.
				RoundedRectangle(cornerRadius: CreditCardMetrics.cornerRadius)
					.fill(.quaternary)
					.frame(height: Self.chartHeight)
			} else if points.isEmpty {
				Text("Enter grades to see your GPA by semester.", bundle: .module)
					.font(.footnote)
					.foregroundStyle(.secondary)
					.frame(maxWidth: .infinity, minHeight: Self.chartHeight)
			} else {
				GPATrendChart(points: points)
					.frame(height: Self.chartHeight)
			}
		}
		.padding(CreditCardMetrics.padding * 2)
		.background(Color(uiColor: .secondarySystemBackground), in: .rect(cornerRadius: CreditCardMetrics.largeCornerRadius))
	}
}

/// The summary card with the estimates disclaimer under it.
private struct GPASummaryColumn: View {
	let gpa: Double?
	let earnedCredits: Int
	let graduationCredits: Int
	let isReady: Bool
	let namespace: Namespace.ID
	let onTap: () -> Void

	var body: some View {
		VStack(alignment: .leading, spacing: 12) {
			GPASummaryCard(
				gpa: gpa,
				earnedCredits: earnedCredits,
				graduationCredits: graduationCredits,
				isReady: isReady,
				namespace: namespace,
				onTap: onTap
			)

			Text("GPA and credits are estimates based on the grades you enter, and are for your reference only. Confirm your graduation requirements with KAIST's official academic records.", bundle: .module)
				.font(.footnote)
				.foregroundStyle(.secondary)
				.padding(.horizontal, 4)
		}
	}
}

/// Cumulative GPA and credits towards graduation; opens Credit Requirements.
private struct GPASummaryCard: View {
	let gpa: Double?
	let earnedCredits: Int
	let graduationCredits: Int
	/// Semesters load one by one; until all have, the card is redacted and disabled.
	let isReady: Bool
	let namespace: Namespace.ID
	let onTap: () -> Void

	private let cornerRadius = CreditCardMetrics.largeCornerRadius

	var body: some View {
		Button {
			onTap()
		} label: {
			GPASummaryContent(gpa: gpa, earnedCredits: earnedCredits, graduationCredits: graduationCredits)
				.padding(CreditCardMetrics.padding * 2)
				.background(Color(uiColor: .secondarySystemBackground), in: .rect(cornerRadius: cornerRadius))
				.contentShape(.rect(cornerRadius: cornerRadius))
		}
		.buttonStyle(.plain)
		.accessibilityHint(String(localized: "Shows credits by requirement", bundle: .module))
		.disabled(!isReady)
		.matchedTransitionSource(id: CreditTransitionID.requirements, in: namespace) { source in
			source.clipShape(.rect(cornerRadius: cornerRadius))
		}
		.redacted(reason: isReady ? [] : .placeholder)
	}
}

/// GPA out of 4.3 and credits against the graduation minimum, with a progress bar
/// and a trailing chevron. Shared by the Credits and Timetable screens' cards, which
/// each add their own card chrome and action.
struct GPASummaryContent: View {
	let gpa: Double?
	let earnedCredits: Int
	let graduationCredits: Int

	var body: some View {
		VStack(alignment: .leading, spacing: 12) {
			HStack(alignment: .firstTextBaseline) {
				SummaryValue(
					title: String(localized: "GPA", bundle: .module),
					value: formattedGPA(gpa),
					total: "4.3",
					alignment: .leading
				)

				Spacer()

				SummaryValue(
					title: String(localized: "Credits", bundle: .module),
					value: "\(earnedCredits)",
					total: "\(graduationCredits)",
					alignment: .trailing
				)

				// Signals the card opens another screen, like the semester cards' chevron.
				Image(systemName: "chevron.right")
					.font(.subheadline)
					.fontWeight(.semibold)
					.foregroundStyle(.tertiary)
					.accessibilityHidden(true)
			}

			ProgressView(value: Double(min(earnedCredits, graduationCredits)), total: Double(max(graduationCredits, 1)))
				.progressViewStyle(ThickLinearProgressViewStyle(height: 18))
				.tint(earnedCredits >= graduationCredits ? .green : .accentColor)
				.accessibilityLabel(String(localized: "Credits towards graduation", bundle: .module))
				.accessibilityValue(String(localized: "\(earnedCredits) of \(graduationCredits) credits", bundle: .module))
		}
	}
}

/// A title over "value/total", e.g. "GPA" over "3.7/4.3".
private struct SummaryValue: View {
	let title: String
	let value: String
	let total: String
	let alignment: HorizontalAlignment

	var body: some View {
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
}

// MARK: - Semesters

/// One semester's silhouette with its GPA and credits; opens grade entry.
private struct SemesterCard: View {
	let item: TakenSemester
	/// `nil` until the semester's table loads; the card is redacted and disabled until then.
	let timetable: Timetable?
	let summary: SemesterGradeSummary?
	let namespace: Namespace.ID
	let onSelect: () -> Void

	var body: some View {
		Button {
			onSelect()
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
					Text(String(localized: "\(formattedGPA(summary?.gpa)) GPA", bundle: .module))

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
			.padding(CreditCardMetrics.padding)
			.background(Color(uiColor: .secondarySystemBackground), in: .rect(cornerRadius: CreditCardMetrics.cornerRadius))
			.contentShape(.rect(cornerRadius: CreditCardMetrics.cornerRadius))
		}
		.buttonStyle(.plain)
		.accessibilityHint(String(localized: "Enter grades", bundle: .module))
		.disabled(timetable == nil)
		// Zoom from the whole card, keeping its rounded corners during the transition.
		.matchedTransitionSource(id: item.id, in: namespace) { source in
			source.clipShape(.rect(cornerRadius: CreditCardMetrics.cornerRadius))
		}
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
