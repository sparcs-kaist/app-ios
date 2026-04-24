//
//  DDayInlineWidgetView.swift
//  BuddyUI
//
//  Created by Soongyu Kwon on 20/04/2026.
//

import SwiftUI
import BuddyDomain

public struct DDayInlineWidgetView: View {
	var entry: DDayEntry
	
	public init(entry: DDayEntry) {
		self.entry = entry
	}
	
	public var body: some View {
		switch entry.type {
		case .endOfSemester(let daysLeft, _):
			Text("Ends in \(daysLeft)d")
		case .startOfSemester(let daysUntil):
			Text("Starts in \(daysUntil)d")
		case .error:
			Text("Unknown Error")
		}
	}
}
