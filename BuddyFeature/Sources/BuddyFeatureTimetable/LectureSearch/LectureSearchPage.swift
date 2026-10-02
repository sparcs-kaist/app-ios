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
/// open in an inspector so the timetable stays in view.
struct LectureSearchPage: View {
  @Bindable var timetableViewModel: TimetableViewModel
  let preview: LectureSearchTimetablePreview
  let timetableDisplayName: String
  let selectedSemester: Semester
  /// The whole screen's size, measured outside the inspector, which narrows this view.
  let containerSize: CGSize
  @Binding var path: NavigationPath

  @State private var viewModel = LectureSearchViewModel()
  @State private var showDepartmentPicker = false
  /// The navigation depth of this screen, so returning to it can be told apart from leaving it.
  @State private var depth: Int?
  /// What the inspector shows, last on top: a lecture or course, then any course opened from it.
  /// Kept here rather than in a navigation stack, which inside the inspector of a pushed screen
  /// would pop that screen.
  @State private var inspectorRoutes: [LectureSearchRoute] = []
  @FocusState private var isSearchFocused: Bool

  @Environment(\.horizontalSizeClass) private var horizontalSizeClass
  @Environment(\.verticalSizeClass) private var verticalSizeClass

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
        .lectureSearchTimetablePreview()
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
    }
    .background(Color.systemGroupedBackground)
    .inspector(isPresented: isInspectorPresented) {
      inspector
    }
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
        selection: $viewModel.filter.departmentIDs,
        onRetry: { await viewModel.fetchDepartments() }
      )
      .toolbarVisibility(.hidden, for: .tabBar)
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
        withAnimation(.smooth) {
          preview.isExpanded = false
        }
      }
    }
    .onChange(of: showDepartmentPicker) {
      // The department picker has no room for the timetable preview.
      withAnimation(.smooth(duration: 0.2)) {
        preview.isCovered = showDepartmentPicker
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

  /// Regular in both directions, as on an iPad or the inner display of iPhone Duo, and wide
  /// enough for two panes. A large iPhone in landscape is regular width but too short for them.
  private var isWide: Bool {
    horizontalSizeClass == .regular
      && verticalSizeClass == .regular
      && containerSize.width > LayoutMetrics.twoColumnWidthThreshold
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
      onSelectDepartments: { showDepartmentPicker = true }
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
    guard isWide, !inspectorRoutes.isEmpty else { return true }
    return containerSize.width - Self.inspectorIdealWidth >= Self.timetablePaneMinWidth + Self.searchPaneMinWidth
  }

  private var inspector: some View {
    Group {
      // Built even while hidden, so only when wide: its screens' titles would otherwise take
      // over the search's navigation bar on a compact screen.
      if isWide, let route = inspectorRoutes.last {
        destination(for: route)
          // A different lecture or course is a different screen, not an update of this one.
          .id(route)
          .environment(\.inspectorNavigation, InspectorNavigation(
            canGoBack: inspectorRoutes.count > 1,
            goBack: { inspectorRoutes.removeLast() },
            close: closeInspector
          ))
      }
    }
    // The timetable is already beside the inspector.
    .environment(\.lectureSearchTimetablePreview, nil)
    .environment(\.openCourse) { id, name in
      inspectorRoutes.append(.course(id: id, name: name))
    }
    .inspectorColumnWidth(min: 320, ideal: Self.inspectorIdealWidth, max: 440)
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
  private static let inspectorIdealWidth: CGFloat = 360

  // MARK: - Navigation

  private var isInspectorPresented: Binding<Bool> {
    Binding(
      get: { isWide && !inspectorRoutes.isEmpty },
      set: { if !$0 { closeInspector() } }
    )
  }

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
      inspectorRoutes = [route]
    } else {
      path.append(route)
    }
  }

  private func closeInspector() {
    inspectorRoutes = []
    timetableViewModel.candidateLecture = nil
  }

  /// Pushes whatever the inspector shows when the screen becomes too narrow for it, such as
  /// when iPhone Duo is closed, so the lecture stays open and previewed.
  private func moveInspectorToStack() {
    let routes = inspectorRoutes
    inspectorRoutes = []
    for route in routes {
      path.append(route)
    }
  }

  private func addLecture(_ lecture: Lecture) {
    // Added from the inspector, the lecture is done with. Added from the results beside it, the
    // inspector may be showing something else, which stays.
    if inspectorRoutes.contains(.lecture(lecture)) {
      closeInspector()
    }
    Task {
      await timetableViewModel.addLecture(lecture: lecture)
    }
  }
}
