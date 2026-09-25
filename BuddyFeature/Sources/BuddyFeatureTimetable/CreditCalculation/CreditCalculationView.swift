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

		return VStack(alignment: .leading, spacing: 8) {
			HStack(spacing: 4) {
				Text(item.title)
				
				Image(systemName: "chevron.right")
					.foregroundStyle(.tertiary)
			}
			.font(.subheadline)
			.fontWeight(.semibold)

			TimetableSilhouetteView(timetable: timetable)
				.aspectRatio(1, contentMode: .fit)

			HStack(spacing: 4) {
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
		.task { await viewModel.loadTimetable(for: item) }
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
			]
		))
	}
}
