//
//  LectureEntity.swift
//  BuddyIntents
//

import AppIntents
import CoreSpotlight
import BuddyDomain
import BuddyDataCore

/// A lecture in the active timetable, one per section the user takes, so Siri
/// can list this semester's lectures or answer "who teaches Data Structures?".
/// There's no App Schema for courses, so this is a plain indexed entity.
public struct LectureEntity: IndexedEntity {
  public static let typeDisplayRepresentation: TypeDisplayRepresentation = "Lecture"
  public static let defaultQuery = LectureQuery()

  /// The OTL lecture ID, the same on every device.
  public let id: Int

  @Property(title: "Name", indexingKey: \.title)
  public var name: String

  @Property(title: "Course Code")
  public var code: String

  @Property(title: "Professors")
  public var professors: String

  @Property(title: "Credits")
  public var credits: Int

  @Property(title: "Department")
  public var department: String

  /// e.g. "Mon/Wed 09:00–10:30 · E11 304".
  @Property(title: "Schedule", indexingKey: \.contentDescription)
  public var schedule: String

  public var displayRepresentation: DisplayRepresentation {
    DisplayRepresentation(
      title: "\(name)",
      subtitle: "\(schedule)",
      image: .init(systemName: "book")
    )
  }

  /// The code, professors and lecture terms (수업, 강의, …) are searchable too.
  public var attributeSet: CSSearchableItemAttributeSet {
    let attributes = defaultAttributeSet
    attributes.keywords = [code, professors, department] + ClassEventBuilder.lectureKeywords
    return attributes
  }

  init(_ lecture: Lecture) {
    self.id = lecture.id
    self.name = lecture.name
    self.code = lecture.code
    self.professors = lecture.professors.map(\.name).joined(separator: ", ")
    self.credits = lecture.credit
    self.department = lecture.department.name
    self.schedule = ClassEventBuilder.weeklySchedule(of: lecture)
  }

  /// The active timetable's lectures, in timetable order.
  static func all(for active: ActiveTimetable) -> [LectureEntity] {
    active.timetable.lectures.map(LectureEntity.init)
  }
}

@available(iOS 27.0, *)
extension LectureEntity: SyncableEntity {}

public struct LectureQuery: EnumerableEntityQuery {
  public init() {}

  public func entities(for identifiers: [Int]) async throws -> [LectureEntity] {
    try await allEntities().filter { identifiers.contains($0.id) }
  }

  public func allEntities() async throws -> [LectureEntity] {
    guard let active = await ActiveTimetableResolver.app()?.resolve() else { return [] }
    return LectureEntity.all(for: active)
  }
}
