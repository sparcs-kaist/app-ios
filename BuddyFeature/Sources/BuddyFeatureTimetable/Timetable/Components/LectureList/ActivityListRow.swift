//
//  ActivityListRow.swift
//  BuddyFeature
//
//  Created by Soongyu Kwon on 11/9/26.
//

import SwiftUI
import BuddyDomain
import TimetableUI

struct ActivityListRow: View {
	let activity: TimetableActivity
	@Environment(\.timetableTheme) private var theme

	var body: some View {
		HStack(alignment: .center) {
			Circle()
				.frame(width: 12, height: 12)
				.foregroundStyle(theme.color(forActivityID: activity.id))
			
			VStack(alignment: .leading) {
				Text(activity.title)
					.font(.headline)
					.lineLimit(1)
				
				HStack {
					makeLabel(timesDescription, systemImage: "clock")
					if !activity.location.isEmpty {
						makeLabel(activity.location, systemImage: "mappin.and.ellipse")
					}
				}
				.font(.caption)
				.foregroundStyle(.secondary)
			}
			
			Spacer()
		}
	}
	
	/// Every time range, e.g. "Mon 10:00 – 11:00, Fri 14:00 – 15:00".
	private var timesDescription: String {
		activity.times
			.map { "\($0.day.stringValue) \(TimetableTimeSelection.formattedTime($0.begin)) – \(TimetableTimeSelection.formattedTime($0.end))" }
			.formatted(.list(type: .and, width: .narrow))
	}

	private func makeLabel(_ text: String, systemImage: String) -> some View {
		HStack(alignment: .center, spacing: 4) {
			Image(systemName: systemImage)
			Text(text)
				.lineLimit(1)
		}
	}
}
