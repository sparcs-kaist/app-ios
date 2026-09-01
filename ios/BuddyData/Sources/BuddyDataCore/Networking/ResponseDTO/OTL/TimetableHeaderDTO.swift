//
//  TimetableHeaderDTO.swift
//  BuddyData
//
//  Created by Soongyu Kwon on 17/04/2026.
//

import Foundation
import BuddyDomain

struct TimetableHeaderDTO: Codable {
	let id: Int
	let name: String
}


extension TimetableHeaderDTO {
	func toModel() -> TimetableHeader {
		TimetableHeader(id: id, name: name)
	}
}
