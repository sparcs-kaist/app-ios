//
//  TimetableQuery.swift
//  soap
//
//  Created by Soongyu Kwon on 18/04/2026.
//

import AppIntents
import BuddyDomain
import BuddyDataCore

struct TimetableQuery: EntityQuery {
	
	func entities(for identifiers: [Int]) async throws -> [TimetableEntity] {
		let all = try await loadAll()
		return all.filter { identifiers.contains($0.id) }
	}
	
	func suggestedEntities() async throws -> [TimetableEntity] {
		try await loadAll()
	}
	
	private func loadAll() async throws -> [TimetableEntity] {
		let timetableService = TimetableService()
    // setup still configures a cache-backed use case if token refresh fails offline.
		try? await timetableService.setup()
		
		guard let timetableUseCase = timetableService.timetableUseCase else {
			return []
		}
		
		return await TimetableEntity.semesters(timetableUseCase).flatMap(TimetableEntity.entities(in:))
	}
}
