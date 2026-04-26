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
		case .endOfSemester(let daysLeft, _, _):
			Text("Ends in \(daysLeft) days")
		case .startOfSemester(let daysUntil, _):
			Text("Starts in \(daysUntil) days")
		case .error:
			Text("Sign in Required")
		}
	}
}
