//
//  DDayCircularWidgetView.swift
//  BuddyUI
//
//  Created by Soongyu Kwon on 20/04/2026.
//

import SwiftUI
import WidgetKit

public struct DDayCircularWidgetView: View {
	@Environment(\.widgetRenderingMode) var renderingMode

	var entry: DDayEntry

	public init(entry: DDayEntry) {
		self.entry = entry
	}

	private var accentColor: Color {
		renderingMode == .fullColor ? .indigo : .primary
	}

	public var body: some View {
		switch entry.type {
		case .endOfSemester(let daysLeft, let progress, _):
			Gauge(
				value: progress,
				label: {},
				currentValueLabel: {
					Text(formattedDDay(from: daysLeft))
				}
			)
			.gaugeStyle(.accessoryCircularCapacity)
			.tint(accentColor)
			.widgetAccentable()
		case .startOfSemester(let daysUntil, _):
			Gauge(
				value: 0,
				label: {},
				currentValueLabel: {
					Text(formattedDDay(from: daysUntil))
				}
			)
			.gaugeStyle(.accessoryCircularCapacity)
			.tint(accentColor)
			.widgetAccentable()
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
		VStack(spacing: 4) {
			Image(systemName: "arrow.up.right.square")
			Text("Sign in")
		}
	}
}
