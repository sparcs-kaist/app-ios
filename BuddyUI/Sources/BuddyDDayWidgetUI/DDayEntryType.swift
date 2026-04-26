//
//  DDayEntryType.swift
//  BuddyUI
//
//  Created by Soongyu Kwon on 20/04/2026.
//

import Foundation

public enum DDayEntryType {
	case endOfSemester(daysLeft: Int, progress: Double, description: String)
	case startOfSemester(daysUntil: Int, description: String)
	case error
}
