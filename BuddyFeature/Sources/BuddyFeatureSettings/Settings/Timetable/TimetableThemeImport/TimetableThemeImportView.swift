//
//  TimetableThemeImportView.swift
//  BuddyFeature
//
//  Created by Soongyu Kwon on 16/09/2026.
//

import SwiftUI
import BuddyDomain

public enum TimetableThemeImportViewState: Equatable {
	case loading
	case loaded(theme: TimetableTheme)
	case failed(message: String)
}

struct TimetableThemeImportView: View {
	let code: String
	/// Called with the fetched theme when the person chooses to keep it.
	let onImport: (TimetableTheme) -> Void
	
	@Environment(\.dismiss) private var dismiss
	@State private var viewModel = TimetableThemeImportViewModel()
	
	var body: some View {
		NavigationStack {
			VStack {
				switch viewModel.viewState {
				case .loading:
					Spacer()
					loadingView
					Spacer()
				case .loaded(let theme):
					ThemedSampleGrid(theme: theme, timetable: TimetableThemeSample.timetable)
						.transition(.blurReplace)
					
					Spacer()
					
					loadedView(theme: theme)
					
					Spacer()
				case .failed(let message):
					Spacer()
					failedView(message: message)
					Spacer()
				}
				
				switch viewModel.viewState {
				case .loading:
					Button(action: {}, label: { importLabel })
						.buttonStyle(.glassProminent)
						.disabled(true)
						.transition(.blurReplace)
				case .loaded(let theme):
					Button {
						onImport(theme)
						dismiss()
					} label: {
						importLabel
					}
					.buttonStyle(.glassProminent)
					.accessibilityIdentifier("theme.saveImport")
					.transition(.blurReplace)
				case .failed:
					retryButton
						.transition(.blurReplace)
				}
			}
			.animation(.smooth, value: viewModel.viewState)
			.padding(.horizontal)
			.navigationBarTitleDisplayMode(.inline)
			.navigationTitle(Text("Import Theme", bundle: .module))
		}
		.presentationDragIndicator(.visible)
		.task { await viewModel.fetch(code: code) }
	}
	
	private var loadingView: some View {
		VStack {
			ProgressView()
			Text("Looking for \"\(code)\"...", bundle: .module)
				.font(.caption)
		}
		.foregroundStyle(.secondary)
		.transition(.blurReplace)
	}
	
	private func loadedView(theme: TimetableTheme) -> some View {
		VStack {
			Text(theme.displayName)
				.font(.title2)
				.fontWeight(.semibold)
				.accessibilityIdentifier("theme.importedName")
			
			Text("This theme will be added to My Themes and used right away.", bundle: .module)
				.font(.footnote)
				.foregroundStyle(.secondary)
				.multilineTextAlignment(.center)
				.padding()
		}
		.transition(.blurReplace)
	}
	
	private func failedView(message: String) -> some View {
		VStack {
			Image(systemName: "exclamationmark.triangle")
				.font(.largeTitle)
			
			Text(message)
				.font(.footnote)
				.multilineTextAlignment(.center)
				.padding()
				.accessibilityIdentifier("theme.importError")
		}
		.foregroundStyle(.secondary)
		.transition(.blurReplace)
	}
	
	private var importLabel: some View {
		Label(String(localized: "Add Theme", bundle: .module), systemImage: "square.and.arrow.down")
			.padding(8)
			.frame(maxWidth: .infinity)
	}
	
	private var retryButton: some View {
		Button {
			Task { await viewModel.fetch(code: code) }
		} label: {
			Label(String(localized: "Try Again", bundle: .module), systemImage: "arrow.clockwise")
				.padding(8)
				.frame(maxWidth: .infinity)
		}
		.buttonStyle(.glassProminent)
		.accessibilityIdentifier("theme.importRetry")
	}
}

#Preview {
	@Previewable @State var showSheet = true
	
	NavigationStack {
	}
	.sheet(isPresented: $showSheet) {
		TimetableThemeImportView(code: "ABC123") { _ in }
	}
}
