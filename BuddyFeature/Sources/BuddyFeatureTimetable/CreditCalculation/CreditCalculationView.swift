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
	@State private var viewModel = CreditCalculationViewModel()

	private let columns = Array(repeating: GridItem(.flexible(), spacing: 16), count: 2)

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
		VStack(alignment: .leading, spacing: 8) {
			Text(item.title)
				.font(.subheadline)
				.fontWeight(.semibold)

			TimetableSilhouetteView(timetable: viewModel.timetables[item.id])
				.aspectRatio(1, contentMode: .fit)
		}
		.task { await viewModel.loadTimetable(for: item) }
	}
}


#Preview {
	NavigationStack {
		CreditCalculationView()
	}
}
