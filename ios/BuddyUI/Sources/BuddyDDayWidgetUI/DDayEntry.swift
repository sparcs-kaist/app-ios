//
//  DDayEntry.swift
//  BuddyUI
//
//  Created by Soongyu Kwon on 20/04/2026.
//

import Foundation
import WidgetKit

public struct DDayEntry: TimelineEntry {
	public let date: Date
	public let type: DDayEntryType
	public let relevance: TimelineEntryRelevance
	
	public init(date: Date, type: DDayEntryType, relevance: TimelineEntryRelevance) {
		self.date = date
		self.type = type
		self.relevance = relevance
	}
}
