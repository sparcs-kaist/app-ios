//
//  TimetableHeader.swift
//  BuddyDomain
//
//  Created by Soongyu Kwon on 17/04/2026.
//

import Foundation

public struct TimetableHeader: Identifiable, Codable, Hashable, Sendable {
	public let id: Int
	public let name: String
	
	public init(id: Int, name: String) {
		self.id = id
		self.name = name.isEmpty ? "Untitled" : name
	}
}
