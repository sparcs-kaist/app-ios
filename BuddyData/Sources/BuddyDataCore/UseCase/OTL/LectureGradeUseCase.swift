//
//  LectureGradeUseCase.swift
//  BuddyData
//
//  Created by Soongyu Kwon on 25/09/2026.
//

import Foundation
import SwiftData
import BuddyDomain

/// Stores lecture grades on-device with SwiftData.
public final class LectureGradeUseCase: LectureGradeUseCaseProtocol, Sendable {
  private let modelContainer: ModelContainer

  public init(modelContainer: ModelContainer) {
    self.modelContainer = modelContainer
  }

  /// A dedicated, app-only store; widgets and the watch don't read grades.
  public static func makeContainer() throws -> ModelContainer {
    try ModelContainer(
      for: LectureGradeRecord.self,
      configurations: ModelConfiguration("LectureGrades", groupContainer: .none)
    )
  }

  public func grades(userID: Int) async throws -> [Int: LectureGrade] {
    let context = ModelContext(modelContainer)
    let records = try context.fetch(FetchDescriptor<LectureGradeRecord>(
      predicate: #Predicate { $0.userID == userID }
    ))
    return Dictionary(
      records.compactMap { record in
        LectureGrade(rawValue: record.gradeRawValue).map { (record.lectureID, $0) }
      },
      uniquingKeysWith: { first, _ in first }
    )
  }

  public func setGrade(_ grade: LectureGrade?, lectureID: Int, userID: Int) async throws {
    let context = ModelContext(modelContainer)
    var descriptor = FetchDescriptor<LectureGradeRecord>(
      predicate: #Predicate { $0.userID == userID && $0.lectureID == lectureID }
    )
    descriptor.fetchLimit = 1
    let existing = try context.fetch(descriptor).first

    switch (grade, existing) {
    case let (grade?, record?):
      record.gradeRawValue = grade.rawValue
      record.updatedAt = .now
    case let (grade?, nil):
      context.insert(LectureGradeRecord(userID: userID, lectureID: lectureID, gradeRawValue: grade.rawValue))
    case let (nil, record?):
      context.delete(record)
    case (nil, nil):
      return
    }
    try context.save()
  }
}
