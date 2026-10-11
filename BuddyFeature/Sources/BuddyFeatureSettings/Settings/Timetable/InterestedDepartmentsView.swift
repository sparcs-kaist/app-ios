//
//  InterestedDepartmentsView.swift
//  BuddyFeature
//
//  Created by Soongyu Kwon on 30/09/2026.
//

import SwiftUI
import BuddyDomain
import BuddyFeatureShared
import FirebaseAnalytics

/// Lets the user choose the departments that are listed first when filtering lectures.
struct InterestedDepartmentsView: View {
  @State private var viewModel: TimetableSettingsViewModelProtocol
  @State private var searchText: String = ""

  @Environment(\.dismiss) private var dismiss

  init(_ viewModel: TimetableSettingsViewModelProtocol) {
    self._viewModel = State(initialValue: viewModel)
  }

  var body: some View {
    List {
      switch viewModel.state {
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
            Task { await viewModel.load() }
          }
        }
      case .loaded:
        DepartmentSelectionSections(
          departments: viewModel.departments,
          interestedDepartmentIDs: viewModel.savedDepartmentIDs,
          searchText: searchText,
          selection: $viewModel.selectedDepartmentIDs
        )
      }
    }
    .contentWidth()
    .navigationTitle(String(localized: "Interested Departments", bundle: .module))
    .navigationBarTitleDisplayMode(.inline)
    .searchable(text: $searchText, prompt: Text("Name or code", bundle: .module))
    .scrollDismissesKeyboard(.immediately)
    .toolbar {
      ToolbarItem(placement: .topBarTrailing) {
        Button(String(localized: "Done", bundle: .module), systemImage: "checkmark", role: .confirm) {
          Task {
            if await viewModel.save() {
              dismiss()
            }
          }
        }
        .disabled(!viewModel.hasChanges || viewModel.isSaving)
      }
    }
    .alert(
      viewModel.alertState?.title ?? String(localized: "Error", bundle: .module),
      isPresented: $viewModel.isAlertPresented,
      actions: {
        Button(role: .confirm) { }
      },
      message: {
        Text(viewModel.alertState?.message ?? "")
      }
    )
    .sensoryFeedback(.selection, trigger: viewModel.selectedDepartmentIDs)
    .analyticsScreen(name: "Interested Departments", class: String(describing: Self.self))
  }
}
