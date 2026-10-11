//
//  TimetableSettingsViewModelProtocol.swift
//  BuddyDomain
//
//  Created by Soongyu Kwon on 30/09/2026.
//

import Foundation
import Observation

@MainActor
public protocol TimetableSettingsViewModelProtocol: Observable {
  var state: TimetableSettingsViewState { get }
  var departments: [DepartmentOption] { get }
  /// The interested departments as last stored on the server.
  var savedDepartmentIDs: Set<Int> { get }
  /// The selection being edited; it is only stored once `save()` succeeds.
  var selectedDepartmentIDs: Set<Int> { get set }
  var hasChanges: Bool { get }
  var isSaving: Bool { get }
  var alertState: AlertState? { get set }
  var isAlertPresented: Bool { get set }

  func load() async
  func save() async -> Bool
}
