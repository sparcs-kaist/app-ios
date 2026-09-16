//
//  TimetableThemeImportViewModel.swift
//  BuddyFeature
//
//  Created by Soongyu Kwon on 16/09/2026.
//

import Foundation
import Observation
import Factory
import BuddyDomain

@MainActor
@Observable
public final class TimetableThemeImportViewModel {
	public private(set) var viewState: TimetableThemeImportViewState = .loading
	
	@ObservationIgnored
	@Injected(\.timetableThemeUseCase) private var themeUseCase: TimetableThemeUseCaseProtocol?
	
	/// Looks up the theme behind a share code so it can be previewed before it is
	/// saved. Re-entrant by design: the failure state offers a retry that calls
	/// back in.
	public func fetch(code: String) async {
		viewState = .loading
		do {
			guard let themeUseCase else { throw URLError(.unknown) }
			viewState = .loaded(theme: try await themeUseCase.fetch(code: code))
		} catch NetworkError.notFound {
			viewState = .failed(
				message: String(localized: "No theme found for this code.", bundle: .module)
			)
		} catch {
			viewState = .failed(
				message: String(localized: "Could not load this theme. Please try again.", bundle: .module)
			)
		}
	}
}
