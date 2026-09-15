//
//  TimetableThemeSharingViewModel.swift
//  BuddyFeature
//
//  Created by Soongyu Kwon on 9/15/26.
//

import Foundation
import Observation
import Factory
import BuddyDomain

@MainActor
@Observable
public final class TimetableThemeSharingViewModel {
	public private(set) var viewState: TimetableThemeSharingViewState = .loading
	
	@ObservationIgnored
	@Injected(\.timetableThemeUseCase) private var themeUseCase: TimetableThemeUseCaseProtocol?
	
	/// Uploads the theme and surfaces the code someone else types to import it.
	/// Re-entrant by design: the failure state offers a retry that calls back in.
	public func share(_ theme: TimetableTheme) async {
		viewState = .loading
		do {
			guard let themeUseCase else { throw URLError(.unknown) }
			viewState = .shared(code: try await themeUseCase.share(theme))
		} catch {
			viewState = .failed(
				message: String(localized: "Could not share this theme. Please try again.", bundle: .module)
			)
		}
	}
}
