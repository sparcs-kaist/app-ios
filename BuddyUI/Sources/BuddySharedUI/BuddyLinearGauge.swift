//
//  BuddyLinearGauge.swift
//  BuddyUI
//
//  Created by Soongyu Kwon on 4/26/26.
//

import SwiftUI
import WidgetKit

public struct BuddyLinearGauge: View {
	var progress: Double // 0...1
	var foregroundColor: Color

	public init(progress: Double, foregroundColor: Color = .primary) {
		self.progress = progress
		self.foregroundColor = foregroundColor
	}

	public var body: some View {
		GeometryReader { geo in
			ZStack(alignment: .leading) {
				Capsule()
					.fill(Color.gray.opacity(0.2))

				Capsule()
					.fill(foregroundColor)
					.frame(width: geo.size.width * progress)
					.widgetAccentable()
			}
		}
	}
}
