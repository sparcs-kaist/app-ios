//
//  FriendTimetableView.swift
//  BuddyFeature
//
//  Created by Soongyu Kwon on 28/09/2026.
//

import SwiftUI
import BuddyDomain
import TimetableUI

/// A friend's timetable for one semester at a time: the one they share, or their enrolled
/// lectures when they share none. Read-only; tapping a lecture shows its details.
struct FriendTimetableView: View {
  @State private var viewModel: FriendTimetableViewModel
  @State private var selectedLecture: LectureItem?

  /// Keeps the grid usable on short (landscape) screens, as the main timetable does.
  private static let minimumGridHeight: CGFloat = 500

  init(friend: Friend, term: FriendTimetableTerm? = nil) {
    self._viewModel = State(initialValue: FriendTimetableViewModel(friend: friend, term: term))
  }

  var body: some View {
    GeometryReader { reader in
      content(gridHeight: max(reader.size.height * 0.8, Self.minimumGridHeight))
    }
    .background(Color.systemGroupedBackground)
    .navigationTitle(viewModel.friend.name)
    .toolbarTitleDisplayMode(.inline)
    .toolbar {
      if !viewModel.terms.isEmpty {
        ToolbarItem(placement: .topBarTrailing) {
          semesterMenu
        }
      }
    }
    .task { await viewModel.load() }
    .sheet(item: $selectedLecture) { item in
      NavigationStack {
        LectureDetailView(lecture: item.lecture, onAdd: nil, lectureClass: item.lectureClass)
          .toolbar {
            ToolbarItem(placement: .cancellationAction) {
              Button(String(localized: "Close", bundle: .module), systemImage: "xmark", role: .close) {
                selectedLecture = nil
              }
            }
          }
      }
      .presentationDragIndicator(.visible)
      .presentationDetents([.medium, .large])
      .trailingPresentationPlacement()
    }
  }

  @ViewBuilder
  private func content(gridHeight: CGFloat) -> some View {
    switch viewModel.viewState {
    case .loading:
      ProgressView()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    case .empty:
      ContentUnavailableView {
        Label(String(localized: "No Timetable", bundle: .module), systemImage: "calendar")
      } description: {
        Text("\(viewModel.friend.name) hasn’t shared a timetable or enrolled in any lectures yet.", bundle: .module)
      }
    case .error(let message):
      ContentUnavailableView {
        Label(String(localized: "Unable to Load Timetable", bundle: .module), systemImage: "exclamationmark.triangle")
      } description: {
        Text(message)
      } actions: {
        Button(String(localized: "Try Again", bundle: .module)) {
          Task { await viewModel.load() }
        }
      }
    case .loaded(let friendTimetable):
      ScrollView {
        VStack(alignment: .leading, spacing: 16) {
          HStack {
            sourceLabel(friendTimetable)
            Spacer()
            if !viewModel.sharedLectureIDs.isEmpty {
              Label {
                Text("\(viewModel.sharedLectureIDs.count) Shared", bundle: .module)
              } icon: {
                Image(systemName: "person.2.fill")
              }
              .font(.subheadline)
              .foregroundStyle(.secondary)
            }
          }

          ThemedGridCard {
            TimetableGrid(
              selectedTimetable: friendTimetable.timetable,
              sharedLectureIDs: viewModel.sharedLectureIDs,
              selectedLecture: { showLecture($0) },
              placement: .view
            )
          }
          .frame(height: gridHeight)

          LectureList(
            lectures: friendTimetable.timetable.lectures,
            activities: friendTimetable.timetable.activities,
            selectedLecture: { showLecture($0) },
            sharedLectureIDs: viewModel.sharedLectureIDs
          )
          .timetableCardStyle()
        }
        .padding()
        // Crossfade from one semester's table to the next.
        .animation(.spring, value: friendTimetable)
      }
      .scrollContentWidth()
      .refreshable { await viewModel.load() }
    }
  }

  /// Says whether this is a timetable the friend chose to share or their enrolled lectures.
  private func sourceLabel(_ friendTimetable: FriendTimetable) -> some View {
    Group {
      switch friendTimetable.source {
      case .shared(let name):
        Label(name.isEmpty ? String(localized: "Shared Timetable", bundle: .module) : name, systemImage: "person.2")
      case .enrolment:
        Label(String(localized: "Enrolled Lectures", bundle: .module), systemImage: "graduationcap")
      }
    }
    .font(.subheadline)
    .foregroundStyle(.secondary)
  }

  private var semesterMenu: some View {
    Menu {
      Picker(
        String(localized: "Semester", bundle: .module),
        selection: Binding(
          get: { viewModel.selectedTerm },
          set: { term in
            guard let term else { return }
            Task { await viewModel.select(term) }
          }
        )
      ) {
        ForEach(viewModel.terms) { term in
          Text(term.description).tag(Optional(term))
        }
      }
    } label: {
      if viewModel.isLoadingTimetable, case .loaded = viewModel.viewState {
        ProgressView()
      } else {
        Label(
          viewModel.selectedTerm?.description ?? String(localized: "Semester", bundle: .module),
          systemImage: "calendar"
        )
        .labelStyle(.titleAndIcon)
      }
    }
  }

  private func showLecture(_ item: LectureItem) {
    viewModel.lectureOpened()
    selectedLecture = item
  }
}

#Preview {
  NavigationStack {
    FriendTimetableView(friend: .mock)
  }
}
