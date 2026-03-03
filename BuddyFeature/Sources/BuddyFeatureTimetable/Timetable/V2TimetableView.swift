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

  @Environment(\.colorScheme) private var colorScheme

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
              createTimetable: {
                await viewModel.createTable()
              },
              renameTimetable: { title in
                await viewModel.renameTable(title: title)
              },
              deleteTimetable: {
                await viewModel.deleteTable()
              }
            )
            .redacted(reason: viewModel.isLoading ? .placeholder : [])

            TimetableGrid(
              selectedTimetable: viewModel.timetable,
              candidateLecture: nil,
              selectedLecture: { selectedLecture in

              }
            )
            .padding()
            .background(colorScheme == .light ? Color.secondarySystemGroupedBackground : .clear, in: .rect(cornerRadius: 28))
            .glassEffect(colorScheme == .light ? .identity : .regular, in: .rect(cornerRadius: 28))
            .frame(height: reader.size.height * 0.8)
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
