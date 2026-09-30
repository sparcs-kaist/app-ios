//
//  TimetableSettingsView.swift
//  BuddyFeature
//
//  Created by Soongyu Kwon on 30/09/2026.
//

import SwiftUI
import BuddyDomain
import FirebaseAnalytics

struct TimetableSettingsView: View {
  @State private var viewModel: TimetableSettingsViewModelProtocol

  init(_ viewModel: TimetableSettingsViewModelProtocol = TimetableSettingsViewModel()) {
    self._viewModel = State(initialValue: viewModel)
  }

  var body: some View {
    List {
      Section {
        NavigationLink {
          InterestedDepartmentsView(viewModel)
        } label: {
          LabeledContent(String(localized: "Interested Departments", bundle: .module)) {
            summary
          }
        }
      } footer: {
        Text("Interested departments appear first when you filter lectures by department.", bundle: .module)
      }
    }
    .navigationTitle(String(localized: "Timetable", bundle: .module))
    .task {
      await viewModel.load()
    }
    .analyticsScreen(name: "Timetable Settings", class: String(describing: Self.self))
  }

  @ViewBuilder
  private var summary: some View {
    switch viewModel.state {
    case .loading:
      ProgressView()
    case .loaded:
      let codes = viewModel.departments
        .filter { viewModel.savedDepartmentIDs.contains($0.id) }
        .map(\.code)
      Text(codes.isEmpty ? String(localized: "None", bundle: .module) : codes.joined(separator: ", "))
        .lineLimit(1)
    case .error:
      EmptyView()
    }
  }
}
