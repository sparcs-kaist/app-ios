//
//  LectureDepartmentPicker.swift
//  BuddyFeature
//
//  Created by Soongyu Kwon on 30/09/2026.
//

import SwiftUI
import BuddyDomain
import BuddyFeatureShared

/// A searchable multi-select list of the departments lectures can be filtered by.
struct LectureDepartmentPicker: View {
  let departments: [DepartmentOption]
  let interestedDepartmentIDs: Set<Int>
  let state: LectureSearchViewModel.ViewState
  @Binding var selection: Set<Int>
  let onRetry: () async -> Void

  @State private var searchText: String = ""

  var body: some View {
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
