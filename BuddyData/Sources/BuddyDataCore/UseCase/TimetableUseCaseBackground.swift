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
      semesterKey = Self.myTableKey(year: currentSemester.year, semester: currentSemester.semesterType)
      let myTable = try await fetchMyTable(year: currentSemester.year, semester: currentSemester.semesterType)
      cache?.storeCurrentMyTable(myTable)
      return myTable
    } catch {
      if let semesterKey, let cached = cache?.timetable(forKey: semesterKey) {
        return cached
      }
      return cache?.currentMyTable() ?? Timetable(id: "-myTable", lectures: [])
    }
  }

  public func getMyTable(year: Int, semester: SemesterType) async -> Timetable {
    let key = Self.myTableKey(year: year, semester: semester)
    do {
      return try await fetchMyTable(year: year, semester: semester)
    } catch {
      return cache?.timetable(forKey: key) ?? Timetable(id: key, lectures: [])
    }
  }

  /// Fetches a semester's My Table and caches it under the key the app uses too.
  private func fetchMyTable(year: Int, semester: SemesterType) async throws -> Timetable {
    let myTable = try await otlTimetableRepository.getMyTable(year: year, semester: semester)
    cache?.store(myTable, forKey: Self.myTableKey(year: year, semester: semester))
    return myTable
  }

  /// Matches `Semester.id`, the key `TimetableUseCase` caches My Table under.
  private static func myTableKey(year: Int, semester: SemesterType) -> String {
    "\(year)-\(semester.rawValue)-myTable"
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
		guard let semester = try? await otlTimetableRepository.getCurrentSemester() else {
			return cache?.currentSemester()
		}
		cache?.storeCurrentSemester(semester)
		return semester
	}
}
