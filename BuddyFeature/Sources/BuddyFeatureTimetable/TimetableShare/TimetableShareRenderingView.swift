//
//  TimetableShareRenderingView.swift
//  BuddyFeature
//
//  Created by Soongyu Kwon on 9/23/26.
//

import SwiftUI
import BuddyDomain
import TimetableUI

struct TimetableShareRenderingView: View {
	let semester: Semester
	let timetable: Timetable
	
	@Environment(\.timetableTheme) private var theme
	
	var body: some View {
		VStack {
			ThemedGridCard {
				TimetableGrid(
					selectedTimetable: timetable,
					placement: .render
				)
			}
			.padding([.top, .horizontal])
			.modifier(TimetableShareShadow(isEnabled: theme.backgroundColor == nil))

			TimetableShareRenderingViewHeader(semester: semester.description, credits: timetable.credits)
		}
		.frame(width: 440, height: 780)
		.background(.white, in: .rect(cornerRadius: 36))
		.preferredColorScheme(.light)
	}
}

private struct TimetableShareShadow: ViewModifier {
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

private struct TimetableShareRenderingViewHeader: View {
	let semester: String
	let credits: Int
	
	var body: some View {
		HStack {
			Image(.buddyIcon)
				.resizable()
				.scaledToFit()
				.frame(width: 32, height: 32)
				.foregroundStyle(.tertiary)
			
			VStack(alignment: .leading) {
				Text("Timetable", bundle: .module)
					.textCase(.uppercase)
					.font(.caption.weight(.medium))
					.foregroundStyle(.secondary)
				
				Text(semester)
					.font(.headline)
			}
			
			Spacer()
			
			VStack(alignment: .trailing) {
				Text("Credits", bundle: .module)
					.foregroundStyle(.tertiary)
					.font(.caption2)
					.fontWeight(.medium)
					.textCase(.uppercase)
				
				Text("\(credits)")
					.foregroundStyle(.secondary)
					.fontDesign(.rounded)
					.fontWeight(.semibold)
			}
		}
		.padding(.top, 4)
		.padding([.horizontal, .bottom])
		.padding(.horizontal, 8)
	}
}

#Preview(traits: .sizeThatFitsLayout) {
	TimetableShareRenderingView(semester: Semester.mock, timetable: Timetable.mock)
		.environment(\.timetableTheme, .builtIn[3])
}
