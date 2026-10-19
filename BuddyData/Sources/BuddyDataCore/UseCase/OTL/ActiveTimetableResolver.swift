//
//  ActiveTimetableResolver.swift
//  BuddyData
//

import Foundation
import BuddyDomain

/// The timetable Siri, the widgets' Mirror mode and Spotlight treat as "my timetable".
public struct ActiveTimetable: Sendable, Equatable {
  public enum Source: Sendable, Equatable {
    case myTable
    case userTable(id: Int, title: String)
  }

  public let source: Source
  public let semester: Semester
  public let timetable: Timetable

  public init(source: Source, semester: Semester, timetable: Timetable) {
    self.source = source
    self.semester = semester
    self.timetable = timetable
  }

  /// My Table follows course registration and is read-only in the app.
  public var userTableID: Int? {
    if case .userTable(let id, _) = source { id } else { nil }
  }

  public var title: String {
    switch source {
    case .myTable: String(localized: "My Table", bundle: .module)
    case .userTable(_, let title): title
    }
  }

  /// Every dated class and activity meeting of this table through the semester.
  public var events: [ClassEvent] {
    ClassEventBuilder.occurrences(for: timetable, timetableID: userTableID, semester: semester)
  }
}

/// Resolves the active timetable:
/// 1. the timetable last selected in the Timetable tab;
/// 2. the current semester's My Table, when that selection is My Table, empty,
///    or from another semester.
///
/// Works in the app, widgets and App Intents, and offline through the shared cache.
public struct ActiveTimetableResolver: Sendable {
  private let useCase: TimetableUseCaseBackgroundProtocol
  private let selection: @Sendable () -> TimetableSelectionStore.Selection?

  public init(
    useCase: TimetableUseCaseBackgroundProtocol,
    selection: @escaping @Sendable () -> TimetableSelectionStore.Selection? = { TimetableSelectionStore().selection }
  ) {
    self.useCase = useCase
    self.selection = selection
  }

  /// - Parameter includingTitle: Looks up a user table's name, which costs a
  ///   request. Widgets never show it, so they skip it.
  public func resolve(includingTitle: Bool = true) async -> ActiveTimetable? {
    guard let semester = await useCase.getCurrentSemester() else { return nil }

    if let saved = selection(), saved.matches(semester), let id = saved.timetableID {
      let table = await useCase.getTable(timetableID: id)
      if !table.lectures.isEmpty || !table.activities.isEmpty {
        var title: String?
        if includingTitle {
          title = await useCase.getTableList()
            .first { $0.year == semester.year && $0.semester == semester.semesterType }?
            .timetables.first { $0.id == id }?.name
        }
        return ActiveTimetable(
          source: .userTable(id: id, title: title ?? String(localized: "Timetable", bundle: .module)),
          semester: semester,
          timetable: table
        )
      }
    }

    let myTable = await useCase.getMyTable(year: semester.year, semester: semester.semesterType)
    return ActiveTimetable(source: .myTable, semester: semester, timetable: myTable)
  }
}

public extension ActiveTimetableResolver {
  /// A resolver backed by a fresh `TimetableService`, for widgets, which run
  /// outside the app and its dependency container. Inside the app, use the app's
  /// own use case through `TimetableUseCaseBackgroundAdapter` instead.
  static func makeBackground() async -> ActiveTimetableResolver? {
    let service = TimetableService()
    // Still configures a cache-backed use case when token refresh fails offline.
    try? await service.setup()
    guard let useCase = service.timetableUseCase else { return nil }
    return ActiveTimetableResolver(useCase: useCase)
  }
}
