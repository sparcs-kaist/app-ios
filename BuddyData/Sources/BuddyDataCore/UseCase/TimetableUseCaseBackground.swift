//
//  TimetableUseCaseBackground.swift
//  BuddyData
//
//  Created by Soongyu Kwon on 09/10/2025.
//

import Foundation
import BuddyDomain

public final actor TimetableUseCaseBackground: TimetableUseCaseBackgroundProtocol {
  // MARK: - Dependencies
  private let cache: TimetableCache?
  private let otlTimetableRepository: OTLTimetableRepositoryProtocol

  public init(
    otlTimetableRepository: OTLTimetableRepositoryProtocol,
    cache: TimetableCache? = nil
  ) {
    self.otlTimetableRepository = otlTimetableRepository
    self.cache = cache
  }

  public func getCurrentMyTable() async -> Timetable {
    var semesterKey: String?
    do {
      let currentSemester = try await otlTimetableRepository.getCurrentSemester()
      semesterKey = "\(currentSemester.year)-\(currentSemester.semesterType.rawValue)-myTable"
      let myTable = try await otlTimetableRepository.getMyTable(
        year: currentSemester.year,
        semester: currentSemester.semesterType
      )
      cache?.storeCurrentMyTable(myTable)
      return myTable
    } catch {
      if let semesterKey, let cached = cache?.timetable(forKey: semesterKey) {
        return cached
      }
      return cache?.currentMyTable() ?? Timetable(id: "-myTable", lectures: [])
    }
  }
	
	public func getTable(timetableID: Int) async -> Timetable {
		do {
			let table = try await otlTimetableRepository.getTable(timetableID: timetableID)
      cache?.store(table, forKey: String(timetableID))
      return table
		} catch {
			return cache?.timetable(forKey: String(timetableID)) ?? Timetable(id: String(timetableID), lectures: [])
		}
	}
	
	public func getTableList() async -> [SemesterWithTimetables] {
		do {
			let list = try await otlTimetableRepository.getTableList()
      cache?.storeTimetableList(list)
      return list
		} catch {
			return cache?.timetableList() ?? []
		}
	}
	
	public func getCurrentSemester() async -> Semester? {
		try? await otlTimetableRepository.getCurrentSemester()
	}
}
