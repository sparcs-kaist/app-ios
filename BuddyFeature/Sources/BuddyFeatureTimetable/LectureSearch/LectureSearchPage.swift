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
  /// Non-nil only while an active fold runs vertically through the two panes; see `FoldSplit`.
  @State private var foldSplit: FoldSplit?
  @FocusState private var isSearchFocused: Bool
  /// A lecture whose overlaps the user is being asked to replace, from the shared bar's Add.
  @State private var replacingLecture: Lecture?

  private var viewModel: LectureSearchViewModel { session.searchViewModel }
  private var preview: LectureSearchTimetablePreview { session.preview }
  private var timetableViewModel: TimetableViewModel { session.timetableViewModel }

  var body: some View {
    // One structure for both layouts, so the results keep their state and scroll position when
    // the screen changes size, such as when iPhone Duo is opened or closed.
    HStack(spacing: 0) {
      if isWide {
        // Half-folded, the timetable takes the leading half and the fold band is left empty,
        // so neither the grid nor the results and their search field sit on the crease.
        timetablePane
          .frame(minWidth: foldSplit?.leadingWidth, maxWidth: foldSplit?.leadingWidth ?? .infinity)
          .padding(.trailing, foldSplit?.gutter ?? 0)
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
    // Always the full width, so the fold is measured against the screen. Half-folded with the
    // inspector open, the panes come to a little less than the screen, and a stack that hugged
    // them would be centred, move the fold it measures, and narrow the panes again each pass.
    .frame(maxWidth: .infinity, alignment: .leading)
    .foldSplit($foldSplit)
    .animation(.snappy, value: foldSplit)
    .background(Color.systemGroupedBackground)
    .navigationTitle(String(localized: "Add to \"\(timetableDisplayName)\"", bundle: .module))
    .navigationBarTitleDisplayMode(.inline)
    .toolbarVisibility(.hidden, for: .tabBar)
    .toolbar { inspectorToolbar }
    .lectureReplacementAlert(
      for: $replacingLecture,
      conflicts: { timetableViewModel.timetable?.conflicts(with: $0) ?? [] },
      onReplace: { addLecture($0, replacingConflicts: true) }
    )
    .navigationDestination(for: LectureSearchRoute.self) { route in
      destination(for: route)
        .environment(\.lectureSearchTimetablePreview, preview)
        .environment(\.lectureSearchTimetableName, timetableDisplayName)
        .environment(\.openCourse) { id, name in
          push(.course(id: id, name: name))
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
        .toolbarVisibility(.hidden, for: .tabBar)
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
      guard let depth else { return }
      // Back on the results, the lecture that was open is no longer previewed, unless it has just
      // moved to the inspector.
      if count <= depth && session.inspectorRoot == nil {
        timetableViewModel.candidateLecture = nil
      }
    }
    .onChange(of: isWide, initial: true) { _, isWide in
      // Beside the results, the timetable needs no preview, nor its tips.
      if isWide {
        TimetableOnboarding.skipPreviewSteps()
      }
    }
    .onChange(of: preview.containerHeight) { _, height in
      // Too short a screen to resize on, such as a phone in landscape.
      if height > 0 && !preview.isResizable {
        TimetableOnboarding.complete(.resizePreview)
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

  // MARK: - Shared bar

  /// The inspector's actions, in the window's vertical bar under the search's Back, while it
  /// shares that bar. Elsewhere, as on an iPad, the inspector has a bar of its own.
  @ToolbarContentBuilder
  private var inspectorToolbar: some ToolbarContent {
    if session.sharesWindowBar, session.isInspectorPresented, let route = session.inspectorTopRoute {
      ToolbarItemGroup(placement: .topBarTrailing) {
        if !session.inspectorPath.isEmpty {
          Button(String(localized: "Back", bundle: .module), systemImage: "chevron.backward") {
            session.inspectorPath.removeLast()
          }
        }
        Button(String(localized: "Close", bundle: .module), systemImage: "xmark", role: .close) {
          session.closeInspector()
        }
        switch route {
        case .lecture(let lecture):
          wishlistButton(for: lecture)
          addButton(for: lecture)
        case .course:
          professorMenu
        }
      }
    }
  }

  private func wishlistButton(for lecture: Lecture) -> some View {
    let isWishlisted = viewModel.isWishlisted(lecture)
    return Button(
      isWishlisted
        ? String(localized: "Remove from Wishlist", bundle: .module)
        : String(localized: "Add to Wishlist", bundle: .module),
      systemImage: isWishlisted ? "heart.fill" : "heart"
    ) {
      Task { await viewModel.toggleWishlist(lecture) }
    }
    .tint(isWishlisted ? .pink : nil)
  }

  @ViewBuilder
  private func addButton(for lecture: Lecture) -> some View {
    let timetable = timetableViewModel.timetable
    if timetable?.contains(lecture) ?? false {
      Button(String(localized: "Added", bundle: .module), systemImage: "checkmark") { }
        .disabled(true)
    } else {
      let conflicts = timetable?.conflicts(with: lecture) ?? []
      Button(String(localized: "Add", bundle: .module), systemImage: "plus") {
        // Still tappable when it overlaps, so it can offer to replace what it overlaps.
        if conflicts.isEmpty {
          addLecture(lecture, replacingConflicts: false)
        } else {
          replacingLecture = lecture
        }
      }
    }
  }

  @ViewBuilder
  private var professorMenu: some View {
    // Only worth offering when the course has had more than one professor.
    if let menu = session.inspectorProfessorMenu, menu.professors.count > 1 {
      Menu(
        menu.professors.first { $0.id == menu.selectedID }?.name
          ?? String(localized: "All Professors", bundle: .module),
        systemImage: "person.2"
      ) {
        Picker(
          String(localized: "All Professors", bundle: .module),
          selection: Binding(get: { menu.selectedID }, set: { menu.select($0) })
        ) {
          Label(String(localized: "All Professors", bundle: .module), systemImage: "person.2")
            .tag(Int?.none)
          ForEach(menu.professors) { professor in
            Text(professor.name).tag(Optional(professor.id))
          }
        }
      }
    }
  }

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
      push(route)
    }
  }

  /// Pushes a lecture or course on the stack, keeping the session's record of it.
  private func push(_ route: LectureSearchRoute) {
    path.append(route)
    session.stackRoutes.append(route)
  }


  private func addLecture(_ lecture: Lecture, replacingConflicts: Bool) {
    session.addLecture(lecture, replacingConflicts: replacingConflicts)
  }
}
