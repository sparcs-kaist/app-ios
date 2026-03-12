//
//  TimetableView.swift
//  BuddyFeature
//
//  Created by Soongyu Kwon on 28/02/2026.
//

import SwiftUI
import BuddyDomain
import BuddyFeatureShared
import FirebaseAnalytics
import TimetableUI

public struct TimetableView: View {
  @Bindable private var viewModel: TimetableViewModel

  @State private var selectedLecture: LectureItem? = nil
  @State private var showSearchSheet: Bool = false
  @State private var selectedDetent: PresentationDetent = .medium

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
              selectedTimetable: viewModel.timetableWithCandidate,
              candidateLecture: viewModel.candidateLecture,
              selectedLecture: { selectedLecture in
                self.selectedLecture = selectedLecture
              },
              onDelete: { lecture in
                Task {
                  await viewModel.deleteLecture(lecture: lecture)
                }
              },
              placement: .view
            )
            .animation(nil, value: viewModel.selectedSemester)
            .padding()
            .background(colorScheme == .light ? Color.secondarySystemGroupedBackground : .clear, in: .rect(cornerRadius: 28))
            .glassEffect(colorScheme == .light ? .identity : .regular, in: .rect(cornerRadius: 28))
            .frame(height: reader.size.height * 0.8)

            TimetableCreditGraph(selectedTimetable: viewModel.timetable)
              .padding()
              .background(colorScheme == .light ? Color.secondarySystemGroupedBackground : .clear, in: .rect(cornerRadius: 28))
              .glassEffect(colorScheme == .light ? .identity : .regular, in: .rect(cornerRadius: 28))

            TimetableSummaryView(selectedTimetable: viewModel.timetable)
              .padding()
              .background(colorScheme == .light ? Color.secondarySystemGroupedBackground : .clear, in: .rect(cornerRadius: 28))
              .glassEffect(colorScheme == .light ? .identity : .regular, in: .rect(cornerRadius: 28))
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
        .toolbar {
          ToolbarItem(placement: .topBarTrailing) {
            Button("Add Lecture", systemImage: "plus") {
              showSearchSheet = true
            }
            .disabled(viewModel.selectedTimetableID == nil)
          }
        }
        .sheet(item: $selectedLecture) { (item: LectureItem) in
          NavigationStack {
            LectureDetailView(
              lecture: item.lecture,
              onAdd: nil,
              isOverlapping: false,
              lectureClass: item.lectureClass
            )
            .presentationDragIndicator(.visible)
            .presentationDetents([.medium, .large])
          }
        }
        .sheet(isPresented: $showSearchSheet) {
          if let selectedSemester = viewModel.selectedSemester {
            LectureSearchView(
              detent: $selectedDetent,
              timetableDisplayName: displayName,
              selectedSemester: selectedSemester,
              candidateLecture: $viewModel.candidateLecture,
              onAdd: { lecture in
                Task {
                  await viewModel.addLecture(lecture: lecture)
                }
              }
            )
            .presentationDetents([.height(130), .medium, .large], selection: $selectedDetent)
            .onAppear {
              selectedDetent = .medium
            }
          }
        }
      }
    }
  }

  private var displayName: String {
    guard let timetable = selectedTimetable else {
      return "My Table"
    }
    return timetable.title.isEmpty ? "Untitled" : timetable.title
  }

  private var selectedTimetable: TimetableSummary? {
    viewModel.timetables.first(where: { $0.id == viewModel.selectedTimetableID })
  }

  public init(_ viewModel: TimetableViewModel) {
    self.viewModel = viewModel
  }
}
