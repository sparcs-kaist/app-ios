//
//  DDayRectangleWidgetView.swift
//  BuddyUI
//
//  Created by Soongyu Kwon on 4/26/26.
//

import SwiftUI
import BuddyDomain
import BuddySharedUI

public struct DDayRectangleWidgetView: View {
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
		case .endOfSemester(let daysLeft, let progress, let description):
			VStack(alignment: .leading, spacing: 2) {
				HStack(alignment: .center) {
					Circle()
						.frame(width: 12, height: 12)

					Text(description)
						.fontDesign(.rounded)
						.lineLimit(1)
						.fontWeight(.semibold)
				}
				.foregroundStyle(accentColor)
				.widgetAccentable()

				Text("Ends in \(daysLeft) days", bundle: .module)

				BuddyLinearGauge(progress: progress, foregroundColor: accentColor)
					.frame(height: 8)
					.padding(.top, 4)
			}
		case .startOfSemester(let daysUntil, let description):
			VStack(alignment: .leading, spacing: 2) {
				HStack(alignment: .center) {
					Circle()
						.frame(width: 12, height: 12)

					Text(description)
						.fontDesign(.rounded)
						.lineLimit(1)
						.fontWeight(.semibold)
				}
				.foregroundStyle(accentColor)
				.widgetAccentable()

				Text("Starts in \(daysUntil) days", bundle: .module)

				BuddyLinearGauge(progress: 0, foregroundColor: accentColor)
					.frame(height: 8)
					.padding(.top, 4)
			}
		case .error:
			signInRequiredView
		}
	}
	
	private var signInRequiredView: some View {
		VStack(alignment: .leading, spacing: 2) {
			HStack(alignment: .center) {
				Circle()
					.frame(width: 12, height: 12)
					.padding(.top, 2)
				
				Text("Sign in Required", bundle: .module)
					.minimumScaleFactor(0.9)
					.lineLimit(1)
					.fontWeight(.semibold)
			}
			.foregroundStyle(Color.accentColor)
			
			HStack {
				Text("Open Buddy on your iPhone to continue", bundle: .module)
					.multilineTextAlignment(.leading)
				Spacer()
			}
			.minimumScaleFactor(0.8)
		}
	}
}
