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
  @AppStorage(LectureSearchStyle.storageKey) private var lectureSearchStyle: LectureSearchStyle = .sheet

  init(_ viewModel: TimetableSettingsViewModelProtocol = TimetableSettingsViewModel()) {
    self._viewModel = State(initialValue: viewModel)
  }

  var body: some View {
    List {
      Section {
        Picker(String(localized: "Lecture Search", bundle: .module), selection: $lectureSearchStyle) {
          ForEach(LectureSearchStyle.allCases) { style in
            Text(style.title).tag(style)
          }
        }
        .pickerStyle(.inline)
        .labelsHidden()
      } header: {
        Text("Adding Lectures", bundle: .module)
      } footer: {
        Text(lectureSearchStyle.footer)
      }

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

private extension LectureSearchStyle {
  var title: String {
    switch self {
    case .sheet: String(localized: "Sheet", bundle: .module)
    case .fullScreen: String(localized: "Full Screen", bundle: .module)
    }
  }

  var footer: String {
    switch self {
    case .sheet:
      String(localized: "Lecture search opens in a sheet, with the timetable behind it.", bundle: .module)
    case .fullScreen:
      String(localized: "Lecture search takes the whole screen, with a timetable preview a tap away. On larger screens the timetable stays beside the results.", bundle: .module)
    }
  }
}
