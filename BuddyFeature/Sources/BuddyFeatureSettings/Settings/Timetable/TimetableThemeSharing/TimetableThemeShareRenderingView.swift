//
//  TimetableThemeShareRenderingView.swift
//  BuddyFeature
//
//  Created by Soongyu Kwon on 9/24/26.
//

import SwiftUI
import BuddyDomain
import TimetableUI

/// The offscreen-rendered card exported when sharing a theme as an image or an
/// Instagram story. Mirrors the timetable share design, with the import code
/// where the timetable card shows credits.
struct TimetableThemeShareRenderingView: View {
	let theme: TimetableTheme
	let code: String

	var body: some View {
		VStack {
			ThemedSampleGridCard(theme: theme)
				.padding([.top, .horizontal])
				.modifier(ThemeShareShadow(isEnabled: theme.backgroundColor == nil))

			TimetableThemeShareRenderingViewHeader(name: theme.displayName, code: code)
		}
		.frame(width: 440, height: 600)
		.background(.white, in: .rect(cornerRadius: 36))
		.preferredColorScheme(.light)
	}
}

/// Same treatment as the timetable feature's `ThemedGridCard`, which this module
/// cannot import: a theme that opts into a background replaces the card's fill.
private struct ThemedSampleGridCard: View {
	let theme: TimetableTheme

	var body: some View {
		TimetableGrid(
			selectedTimetable: TimetableThemeSample.timetable,
			beginTime: TimetableThemeSample.beginTime,
			endTime: TimetableThemeSample.endTime,
			placement: .render
		)
		.timetableTheme(theme)
		.padding()
		.background(theme.backgroundColor ?? .secondarySystemGroupedBackground, in: .rect(cornerRadius: 28))
	}
}

private struct ThemeShareShadow: ViewModifier {
	let isEnabled: Bool

	func body(content: Content) -> some View {
		if isEnabled {
			content
				.shadow(color: .black.opacity(0.04), radius: 2, x: 0, y: 1)
				.shadow(color: .black.opacity(0.08), radius: 16, x: 0, y: 8)
		} else {
			content
		}
	}
}

private struct TimetableThemeShareRenderingViewHeader: View {
	let name: String
	let code: String

	var body: some View {
		HStack {
			Image(.buddyIcon)
				.resizable()
				.scaledToFit()
				.frame(width: 32, height: 32)
				.foregroundStyle(.tertiary)

			VStack(alignment: .leading) {
				Text("Timetable Theme", bundle: .module)
					.textCase(.uppercase)
					.font(.caption.weight(.medium))
					.foregroundStyle(.secondary)

				Text(name)
					.font(.headline)
			}

			Spacer()

			VStack(alignment: .trailing) {
				Text("Code", bundle: .module)
					.foregroundStyle(.tertiary)
					.font(.caption2)
					.fontWeight(.medium)
					.textCase(.uppercase)

				Text(code)
					.foregroundStyle(.secondary)
					.fontDesign(.monospaced)
					.fontWeight(.semibold)
			}
		}
		.padding(.top, 4)
		.padding([.horizontal, .bottom])
		.padding(.horizontal, 8)
	}
}

#Preview(traits: .sizeThatFitsLayout) {
	TimetableThemeShareRenderingView(
		theme: TimetableTheme.builtIn.first { $0.id == "builtin.spring" }!,
		code: "AB12CD"
	)
}
