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
	
	var body: some View {
		HStack(alignment: .center) {
			Circle()
				.frame(width: 12, height: 12)
				.foregroundStyle(activity.backgroundColor)
			
			VStack(alignment: .leading) {
				Text(activity.title)
					.font(.headline)
					.lineLimit(1)
				
				HStack {
					makeLabel("\(activity.day.stringValue) \(TimetableTimeSelection.formattedTime(activity.begin)) – \(TimetableTimeSelection.formattedTime(activity.end))", systemImage: "clock")
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
	
	private func makeLabel(_ text: String, systemImage: String) -> some View {
		HStack(alignment: .center, spacing: 4) {
			Image(systemName: systemImage)
			Text(text)
				.lineLimit(1)
		}
	}
}
