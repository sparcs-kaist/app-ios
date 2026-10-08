//
//  TimetableSettingsViewModel.swift
//  BuddyFeature
//
//  Created by Soongyu Kwon on 30/09/2026.
//

import Foundation
import Factory
import BuddyDomain
import os

private let logger = Logger(subsystem: "org.sparcs.soap", category: "TimetableSettingsViewModel")

@MainActor
@Observable
final class TimetableSettingsViewModel: TimetableSettingsViewModelProtocol {
  // MARK: - Properties
  var state: TimetableSettingsViewState = .loading
  var departments: [DepartmentOption] = []
  var savedDepartmentIDs: Set<Int> = []
  var selectedDepartmentIDs: Set<Int> = []
  var isSaving: Bool = false
  var alertState: AlertState?
  var isAlertPresented: Bool = false

  var hasChanges: Bool { selectedDepartmentIDs != savedDepartmentIDs }

  // MARK: - Dependencies
  @ObservationIgnored @Injected(\.userUseCase) private var userUseCase: UserUseCaseProtocol?
  @ObservationIgnored @Injected(\.v2LectureUseCase) private var lectureUseCase: LectureUseCaseProtocol?
  @ObservationIgnored @Injected(\.crashlyticsService) private var crashlyticsService: CrashlyticsServiceProtocol?

  // MARK: - Functions
  func load() async {
    guard let userUseCase, let lectureUseCase else { return }

    // Reloading when the screen reappears should not flash a spinner over a list already shown.
    if departments.isEmpty {
      state = .loading
    }
    do {
      async let options = lectureUseCase.fetchDepartmentOptions()
      try await userUseCase.fetchOTLUser()
      departments = try await options

      let interestedIDs = Set(await userUseCase.otlUser?.interestedDepartments.map(\.id) ?? [])
      savedDepartmentIDs = interestedIDs
      selectedDepartmentIDs = interestedIDs
      state = .loaded
    } catch {
      logger.error("Failed to load interested departments: \(error.localizedDescription, privacy: .public)")
      crashlyticsService?.recordException(error: error)
      state = .error(message: error.localizedDescription)
    }
  }

  func save() async -> Bool {
    guard let userUseCase else { return false }

    isSaving = true
    defer { isSaving = false }

    do {
      try await userUseCase.updateInterestedDepartments(departmentIDs: selectedDepartmentIDs.sorted())
      savedDepartmentIDs = selectedDepartmentIDs
      return true
    } catch {
      logger.error("Failed to save interested departments: \(error.localizedDescription, privacy: .public)")
      crashlyticsService?.recordException(error: error)
      alertState = .init(
        title: String(localized: "Failed to save interested departments.", bundle: .module),
        message: error.localizedDescription
      )
      isAlertPresented = true
      return false
    }
  }
}
