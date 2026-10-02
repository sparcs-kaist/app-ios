//
//  LectureSearchPage.swift
//  BuddyFeature
//
//  Created by Soongyu Kwon on 02/10/2026.
//

import SwiftUI
import FirebaseAnalytics
import BuddyDomain
import BuddyFeatureShared
import TimetableUI

/// Lecture search as a pushed screen, the alternative to the search sheet chosen in Settings.
///
/// On a compact screen the results take the whole view and the timetable is a preview opened
/// from the toolbar, there on every screen pushed from the search. On a larger screen the
/// timetable fills the leading half, the results the trailing half, and lectures and courses
/// open in the session's inspector, which the timetable shows beside the search.
struct LectureSearchPage: View {
  @Bindable var session: LectureSearchSession
  let timetableDisplayName: String
  let selectedSemester: Semester
  /// The whole screen's size, measured outside the inspector, which narrows this view.
  let containerSize: CGSize
  @Binding var path: NavigationPath

  @State private var showDepartmentPicker = false
  @State private var showTimeRangePicker = false
  /// The navigation depth of this screen, so returning to it can be told apart from leaving it.
  @State private var depth: Int?
  @FocusState private var isSearchFocused: Bool

  private var viewModel: LectureSearchViewModel { session.searchViewModel }
  private var preview: LectureSearchTimetablePreview { session.preview }
  private var timetableViewModel: TimetableViewModel { session.timetableViewModel }

  var body: some View {
    // One structure for both layouts, so the results keep their state and scroll position when
    // the screen changes size, such as when iPhone Duo is opened or closed.
    HStack(spacing: 0) {
      if isWide {
        timetablePane
          .frame(maxWidth: .infinity)
      }

      searchList
        // The preview is only needed when the timetable is not already beside the results.
        .lectureSearchTimetablePreview(sizesCard: true)
        .environment(\.lectureSearchTimetablePreview, isWide ? nil : preview)
        // With the inspector open there may not be room for all three. The results then make way
        // for it, keeping their size and scroll position for when it closes.
        .frame(minWidth: isWide ? Self.searchPaneMinWidth : nil)
        .frame(width: showsSearchPane ? nil : 0, alignment: .leading)
        .frame(maxWidth: showsSearchPane ? .infinity : 0)
        // Hidden without clipping, which would also cut the results off under the navigation
        // bar and so lose its soft scroll edge.
        .opacity(showsSearchPane ? 1 : 0)
        .allowsHitTesting(showsSearchPane)
        .accessibilityHidden(!showsSearchPane)

      // A pane of the stack rather than a system inspector, which UIKit resizes the panes for
      // without animation; here the panes narrow as it slides in. Only on a wide screen.
      if session.isInspectorPresented {
        LectureSearchInspector(session: session)
          .transition(.move(edge: .trailing))
      }
    }
    .background(Color.systemGroupedBackground)
    .navigationTitle(String(localized: "Add to \"\(timetableDisplayName)\"", bundle: .module))
    .navigationBarTitleDisplayMode(.inline)
    .toolbarVisibility(.hidden, for: .tabBar)
    .navigationDestination(for: LectureSearchRoute.self) { route in
      destination(for: route)
        .environment(\.lectureSearchTimetablePreview, preview)
        .environment(\.openCourse) { id, name in
          path.append(LectureSearchRoute.course(id: id, name: name))
        }
        .toolbarVisibility(.hidden, for: .tabBar)
        .wishlistErrorAlert(viewModel)
    }
    .navigationDestination(isPresented: $showDepartmentPicker) {
      DepartmentPicker(
        departments: viewModel.departments,
        interestedDepartmentIDs: viewModel.interestedDepartmentIDs,
        state: viewModel.departmentState,
        selection: Bindable(viewModel).filter.departmentIDs,
        onRetry: { await viewModel.fetchDepartments() }
      )
      // The timetable preview stays in place over the picker, as over every screen of the search.
      .lectureSearchTimetablePreview()
      .environment(\.lectureSearchTimetablePreview, isWide ? nil : preview)
      .toolbarVisibility(.hidden, for: .tabBar)
    }
    .navigationDestination(isPresented: $showTimeRangePicker) {
      LectureTimeRangePage(timetable: timetableViewModel.timetable, time: Bindable(viewModel).time)
    }
    .onChange(of: showTimeRangePicker) {
      // The picker is the timetable itself, so the preview steps aside for it, at once rather
      // than animating as the screens change.
      withTransaction(Transaction(animation: nil)) {
        preview.isCovered = showTimeRangePicker
      }
    }
    .onAppear {
      if depth == nil {
        depth = path.count
      }
    }
    .onChange(of: path.count) { _, count in
      // Back on the results, the lecture that was open is no longer previewed.
      if let depth, count <= depth {
        timetableViewModel.candidateLecture = nil
      }
    }
    .onChange(of: isWide) { _, isWide in
      if !isWide {
        moveInspectorToStack()
      }
    }
    .onChange(of: isSearchFocused) {
      // The keyboard leaves too little room for the preview and the results together.
      if isSearchFocused {
        withAnimation(LectureSearchTimetablePreview.animation) {
          preview.isExpanded = false
        }
      }
    }
    .onChange(of: preview.isExpanded) {
      if preview.isExpanded {
        isSearchFocused = false
      }
    }
    .analyticsScreen(name: "Lecture Search", class: String(describing: Self.self))
  }

  // MARK: - Layout

  /// Decided by the timetable from the whole window: the open inspector narrows this screen.
  private var isWide: Bool {
    session.isWide
  }

  private var searchList: some View {
    LectureSearchList(
      viewModel: viewModel,
      timetable: timetableViewModel.timetable,
      selectedSemester: selectedSemester,
      isSearchFocused: $isSearchFocused,
      onOpenLecture: openLecture,
      onOpenCourse: openCourse,
      onAddLecture: addLecture,
      onSelectDepartments: { showDepartmentPicker = true },
      onChooseTimeOnTimetable: { showTimeRangePicker = true }
    )
  }

  private var timetablePane: some View {
    ScrollView {
      ThemedGridCard {
        TimetableGrid(
          selectedTimetable: timetableViewModel.timetableWithCandidate,
          candidateLecture: timetableViewModel.candidateLecture,
          selectedLecture: { item in openLecture(item.lecture) },
          placement: .view
        )
      }
      .containerRelativeFrame(.vertical) { height, _ in
        max(height - Self.panePadding * 2, Self.minimumGridHeight)
      }
      .padding(Self.panePadding)
    }
    .scrollBounceBehavior(.basedOnSize)
    .scrollEdgeEffectStyle(.soft, for: [.top, .bottom])
  }

  private var showsSearchPane: Bool {
    guard session.isInspectorPresented else { return true }
    return containerSize.width - LectureSearchInspector.idealWidth >= Self.timetablePaneMinWidth + Self.searchPaneMinWidth
  }

  private func destination(for route: LectureSearchRoute) -> some View {
    LectureSearchDestination(
      route: route,
      viewModel: viewModel,
      timetable: timetableViewModel.timetable,
      onAdd: addLecture
    )
  }

  private static let panePadding: CGFloat = 16
  private static let minimumGridHeight: CGFloat = 480
  private static let timetablePaneMinWidth: CGFloat = 300
  private static let searchPaneMinWidth: CGFloat = 340

  // MARK: - Navigation


  /// Opens a lecture and draws it into the timetable, unless the timetable already has it.
  private func openLecture(_ lecture: Lecture) {
    isSearchFocused = false
    let isAdded = timetableViewModel.timetable?.contains(lecture) ?? false
    timetableViewModel.candidateLecture = isAdded ? nil : lecture
    show(.lecture(lecture))
  }

  /// Opens a course from the results.
  private func openCourse(id: Int, name: String) {
    isSearchFocused = false
    if isWide {
      // The course replaces any lecture in the inspector, so that lecture is no longer previewed.
      timetableViewModel.candidateLecture = nil
    }
    show(.course(id: id, name: name))
  }

  private func show(_ route: LectureSearchRoute) {
    if isWide {
      session.inspect(route)
    } else {
      path.append(route)
    }
  }

  /// Pushes whatever the inspector shows when the screen becomes too narrow for it, such as
  /// when iPhone Duo is closed, so the lecture stays open and previewed.
  private func moveInspectorToStack() {
    for route in session.takeInspectorRoutes() {
      path.append(route)
    }
  }

  private func addLecture(_ lecture: Lecture) {
    session.addLecture(lecture)
  }
}
