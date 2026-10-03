//
//  DepartmentPicker.swift
//  BuddyFeature
//
//  Created by Soongyu Kwon on 30/09/2026.
//

import SwiftUI
import BuddyDomain

/// A searchable multi-select list of the departments lectures and courses can be filtered by.
public struct DepartmentPicker: View {
  private let departments: [DepartmentOption]
  private let interestedDepartmentIDs: Set<Int>
  private let state: DepartmentOptionsViewState
  @Binding private var selection: Set<Int>
  private let onRetry: () async -> Void

  @State private var searchText: String = ""

  public init(
    departments: [DepartmentOption],
    interestedDepartmentIDs: Set<Int>,
    state: DepartmentOptionsViewState,
    selection: Binding<Set<Int>>,
    onRetry: @escaping () async -> Void
  ) {
    self.departments = departments
    self.interestedDepartmentIDs = interestedDepartmentIDs
    self.state = state
    self._selection = selection
    self.onRetry = onRetry
  }

  public var body: some View {
    List {
      switch state {
      case .loading:
        ProgressView()
          .frame(maxWidth: .infinity)
      case .error(let message):
        ContentUnavailableView {
          Label(String(localized: "Unable to Load Departments", bundle: .module), systemImage: "exclamationmark.circle")
        } description: {
          Text(message)
        } actions: {
          Button(String(localized: "Retry", bundle: .module)) {
            Task { await onRetry() }
          }
        }
      case .loaded:
        DepartmentSelectionSections(
          departments: departments,
          interestedDepartmentIDs: interestedDepartmentIDs,
          searchText: searchText,
          selection: $selection
        )
      }
    }
    .contentWidth()
    .navigationTitle(String(localized: "Department", bundle: .module))
    .scrollEdgeEffectStyle(.soft, for: .top)
    .navigationBarTitleDisplayMode(.inline)
    .searchable(text: $searchText, prompt: Text("Name or code", bundle: .module))
    .scrollDismissesKeyboard(.immediately)
    .toolbar {
      ToolbarItem(placement: .topBarTrailing) {
        Button(String(localized: "Clear", bundle: .module)) {
          selection.removeAll()
        }
        .disabled(selection.isEmpty)
      }
    }
    .sensoryFeedback(.selection, trigger: selection)
  }
}
