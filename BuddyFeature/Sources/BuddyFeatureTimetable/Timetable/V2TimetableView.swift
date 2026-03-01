//
//  V2TimetableView.swift
//  BuddyFeature
//
//  Created by Soongyu Kwon on 28/02/2026.
//

import SwiftUI
import BuddyDomain
import BuddyFeatureShared
import FirebaseAnalytics

public struct V2TimetableView: View {
  @State private var viewModel = V2TimetableViewModel()

  public var body: some View {
    GeometryReader { reader in
      NavigationStack {
        ScrollView {
          VStack(spacing: 28) {
            CompactTimetableSelector(
              semesters: viewModel.semesters,
              selectedSemester: $viewModel.selectedSemester,
              timetables: viewModel.timetables,
              selectedTimetableID: $viewModel.selectedTimetableID,
              renameTimetable: { title in
                await viewModel.renameTable(title: title)
              },
              deleteTimetable: {
                await viewModel.deleteTable()
              }
            )
            .redacted(reason: viewModel.isLoading ? .placeholder : [])
          }
          .padding()
        }
        .background {
          BackgroundGradientView(color: .pink)
            .ignoresSafeArea()
        }
        .navigationTitle("Timetable")
        .toolbarTitleDisplayMode(.inlineLarge)
        .background(Color.systemGroupedBackground)
        .task {
          await viewModel.setup()
        }
      }
    }
  }

  public init() { }
}
