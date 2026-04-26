//
//  DDayCircularWidgetView.swift
//  BuddyUI
//
//  Created by Soongyu Kwon on 20/04/2026.
//

import SwiftUI

public struct DDayCircularWidgetView: View {
	var entry: DDayEntry
	
	public init(entry: DDayEntry) {
		self.entry = entry
	}
	
	public var body: some View {
		switch entry.type {
		case .endOfSemester(let daysLeft, let progress):
			Gauge(
				value: progress,
				label: {},
				currentValueLabel: {
					Text(formattedDDay(from: daysLeft))
				}
			)
			.gaugeStyle(.accessoryCircularCapacity)
		case .startOfSemester(let daysUntil):
			Gauge(
				value: 0,
				label: {},
				currentValueLabel: {
					Text(formattedDDay(from: daysUntil))
				}
			)
			.gaugeStyle(.accessoryCircularCapacity)
		case .error:
			signInRequiredView
		}
	}
	
	private func formattedDDay(from days: Int) -> String {
		if days > 0 {
			return "D-\(days)"
		} else if days < 0 {
			return "D+\(abs(days))"
		}
		
		return "D-Day"
	}
	
	private var signInRequiredView: some View {
		VStack {
			Image(systemName: "arrow.up.right.square")
			Text("Sign in")
		}
	}
}
