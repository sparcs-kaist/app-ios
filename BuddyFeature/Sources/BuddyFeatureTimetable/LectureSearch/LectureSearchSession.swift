//
//  LectureSearchSession.swift
//  BuddyFeature
//
//  Created by Soongyu Kwon on 02/10/2026.
//

import SwiftUI
import UIKit
import BuddyDomain
import TimetableUI

/// One full-screen lecture search, from Add Lecture until the search is left: its results, its
/// timetable preview and what its inspector shows.
@MainActor
@Observable
final class LectureSearchSession {
  let searchViewModel = LectureSearchViewModel()
  let preview: LectureSearchTimetablePreview
  /// Whether the screen has room for the timetable beside the results, and for the inspector.
  var isWide = false
  /// The lecture or course the inspector shows, under any course opened from it.
  var inspectorRoot: LectureSearchRoute?
  var inspectorPath: [LectureSearchRoute] = []
  /// The lectures and courses pushed on the timetable's stack above the search, in order, which
  /// a `NavigationPath` cannot be asked for. When the screen widens they go back to the inspector.
  @ObservationIgnored var stackRoutes: [LectureSearchRoute] = []
  /// The timetable stack's depth with the search on top, below the lectures and courses pushed
  /// from it.
  @ObservationIgnored var stackBase = 0
  /// Whether the window's bar is vertical, as on iPhone Duo's inner display in landscape. The
  /// inspector's actions then join the search's in that one bar instead of a bar of its own,
  /// which would take the window's vertical bar over and leave the search without Back.
  var sharesWindowBar = false
  /// The course page's professors, reported by the inspector's course page for the shared bar.
  var inspectorProfessorMenu: InspectorProfessorMenu?
  /// Observed through its own properties; this only hands it to the search's screens.
  @ObservationIgnored let timetableViewModel: TimetableViewModel

  init(timetableViewModel: TimetableViewModel) {
    self.timetableViewModel = timetableViewModel
    self.preview = LectureSearchTimetablePreview(timetableViewModel: timetableViewModel)
  }

  var isInspectorPresented: Bool {
    isWide && inspectorRoot != nil
  }

  /// The screen the inspector shows on top.
  var inspectorTopRoute: LectureSearchRoute? {
    inspectorPath.last ?? inspectorRoot
  }

  /// Shows a lecture or course in the inspector, in place of whatever it showed.
  func inspect(_ route: LectureSearchRoute) {
    // Opening it narrows the panes beside it, so that is animated; replacing what an open
    // inspector shows moves nothing.
    withAnimation(inspectorRoot == nil ? Self.inspectorAnimation : nil) {
      inspectorPath = []
      inspectorRoot = route
    }
  }

  func closeInspector() {
    // The panes widen back as the inspector leaves.
    withAnimation(inspectorRoot == nil ? nil : Self.inspectorAnimation) {
      inspectorRoot = nil
      inspectorPath = []
      timetableViewModel.candidateLecture = nil
    }
  }

  /// Opens and closes the inspector, and moves the panes beside it with it.
  static let inspectorAnimation: Animation = .smooth(duration: 0.35)

  /// Takes what the inspector shows out of it, root first, such as when the screen becomes too
  /// narrow for it and the screens are pushed instead.
  func takeInspectorRoutes() -> [LectureSearchRoute] {
    let routes = (inspectorRoot.map { [$0] } ?? []) + inspectorPath
    inspectorRoot = nil
    inspectorPath = []
    return routes
  }

  /// Shows screens taken from the stack in the inspector, root first, such as when iPhone Duo is
  /// opened on a lecture pushed while it was closed. In place at once: the panes are already
  /// moving with the screen's new size.
  func restoreInspector(_ routes: [LectureSearchRoute]) {
    guard let root = routes.first else { return }
    inspectorRoot = root
    inspectorPath = Array(routes.dropFirst())
  }

  /// Forgets the lectures and courses popped off the stack with the back button or a swipe.
  func stackDidChange(count: Int) {
    let pushed = max(0, count - stackBase)
    if pushed < stackRoutes.count {
      stackRoutes.removeLast(stackRoutes.count - pushed)
    }
  }

  func addLecture(_ lecture: Lecture, replacingConflicts: Bool = false) {
    // Added from the inspector, the lecture is done with. Added from the results beside it, the
    // inspector may be showing something else, which stays.
    if inspectorRoot == .lecture(lecture) || inspectorPath.contains(.lecture(lecture)) {
      closeInspector()
    }
    Task {
      await timetableViewModel.addLecture(lecture: lecture, replacingConflicts: replacingConflicts)
    }
  }
}

/// The inspector of the full-screen lecture search on a larger screen: a lecture or course with a
/// navigation bar and toolbar of its own, under the search's.
///
/// Its navigation is a UIKit navigation controller rather than a SwiftUI stack. A SwiftUI stack in
/// the inspector of a pushed screen, even in a hosting controller of its own, is taken for part of
/// the timetable's stack and pops the search.
struct LectureSearchInspector: View {
  let session: LectureSearchSession

  var body: some View {
    InspectorNavigationController(
      session: session,
      routes: session.inspectorRoot.map { [$0] + session.inspectorPath } ?? []
    )
    .ignoresSafeArea(edges: .bottom)
    .frame(width: Self.idealWidth)
    .background(Color.systemGroupedBackground, ignoresSafeAreaEdges: .bottom)
    .overlay(alignment: .leading) {
      Divider()
        .ignoresSafeArea(edges: .bottom)
    }
  }

  static let idealWidth: CGFloat = 360
}

/// One screen of the inspector, in its own hosting controller. It fills in that controller's
/// navigation bar itself: a title or toolbar declared in SwiftUI here would go to the search's
/// navigation bar instead.
private struct InspectorScreen: View {
  let session: LectureSearchSession
  let route: LectureSearchRoute
  let isRoot: Bool
  let host: HostedController
  /// The course page's professors, reported by the page for the picker in the bar.
  @State private var professorMenu: InspectorProfessorMenu?

  var body: some View {
    LectureSearchDestination(
      route: route,
      viewModel: session.searchViewModel,
      timetable: session.timetableViewModel.timetable,
      onAdd: session.addLecture
    )
    .environment(\.isInLectureSearchInspector, true)
    .environment(\.openCourse) { id, name in
      session.inspectorPath.append(.course(id: id, name: name))
    }
    .environment(\.reportProfessorMenu) { menu in
      professorMenu = menu
      session.inspectorProfessorMenu = menu
    }
    .wishlistErrorAlert(session.searchViewModel)
    .safeAreaInset(edge: .top, spacing: 0) {
      // In place of the hidden navigation bar's title.
      if session.sharesWindowBar {
        Text(barState.title)
          .font(.headline)
          .lineLimit(1)
          .padding(.horizontal)
          .padding(.vertical, 12)
          .frame(maxWidth: .infinity, alignment: .leading)
          .background(Color.systemGroupedBackground)
      }
    }
    // A hosting controller of its own does not inherit the timetable's environment.
    .timetableThemeFromSettings()
    .onChange(of: barState, initial: true) {
      configureBar()
    }
  }

  // MARK: - Navigation bar

  private struct BarState: Equatable {
    var title: String
    var isWishlisted = false
    var isAdded = false
    var conflicts: [String] = []
    var professors: [Professor] = []
    var selectedProfessorID: Int?
    var sharesWindowBar = false
  }

  private var barState: BarState {
    switch route {
    case .lecture(let lecture):
      let timetable = session.timetableViewModel.timetable
      return BarState(
        title: lecture.name,
        isWishlisted: session.searchViewModel.isWishlisted(lecture),
        isAdded: timetable?.contains(lecture) ?? false,
        conflicts: timetable?.conflicts(with: lecture) ?? [],
        sharesWindowBar: session.sharesWindowBar
      )
    case .course(_, let name):
      return BarState(
        title: name,
        professors: professorMenu?.professors ?? [],
        selectedProfessorID: professorMenu?.selectedID,
        sharesWindowBar: session.sharesWindowBar
      )
    }
  }

  private func configureBar() {
    guard let navigationItem = host.controller?.navigationItem else { return }
    let state = barState
    navigationItem.title = state.title
    navigationItem.largeTitleDisplayMode = .never
    // Sharing the window's vertical bar, the actions are the search's toolbar items; any here,
    // even the back button, would take that bar over. Only the title stays, over the pane.
    navigationItem.hidesBackButton = state.sharesWindowBar
    if state.sharesWindowBar {
      navigationItem.leftBarButtonItem = nil
      navigationItem.rightBarButtonItems = []
      return
    }
    navigationItem.leftBarButtonItem = isRoot
      ? UIBarButtonItem(systemItem: .close, primaryAction: UIAction { _ in session.closeInspector() })
      : nil

    switch route {
    case .lecture(let lecture):
      navigationItem.rightBarButtonItems = [addItem(for: lecture, state: state), wishlistItem(for: lecture, state: state)]
    case .course:
      // Only worth offering when the course has had more than one professor.
      navigationItem.rightBarButtonItems = state.professors.count > 1 ? [professorItem(state: state)] : []
    }
  }

  private func addItem(for lecture: Lecture, state: BarState) -> UIBarButtonItem {
    if state.isAdded {
      let item = UIBarButtonItem(
        title: String(localized: "Added", bundle: .module),
        image: UIImage(systemName: "checkmark"),
        primaryAction: nil
      )
      item.isEnabled = false
      return item
    }
    let item = UIBarButtonItem(
      title: String(localized: "Add", bundle: .module),
      image: UIImage(systemName: "plus"),
      primaryAction: UIAction { _ in
        // Still tappable when it overlaps, so it can offer to replace what it overlaps.
        if state.conflicts.isEmpty {
          session.addLecture(lecture)
        } else {
          showReplaceAlert(for: lecture, conflicts: state.conflicts)
        }
      }
    )
    item.style = state.conflicts.isEmpty ? .prominent : .plain
    return item
  }

  private func wishlistItem(for lecture: Lecture, state: BarState) -> UIBarButtonItem {
    let item = UIBarButtonItem(
      title: state.isWishlisted
        ? String(localized: "Remove from Wishlist", bundle: .module)
        : String(localized: "Add to Wishlist", bundle: .module),
      image: UIImage(systemName: state.isWishlisted ? "heart.fill" : "heart"),
      primaryAction: UIAction { _ in
        Task { await session.searchViewModel.toggleWishlist(lecture) }
      }
    )
    item.tintColor = state.isWishlisted ? .systemPink : nil
    return item
  }

  private func professorItem(state: BarState) -> UIBarButtonItem {
    let select = professorMenu?.select
    let all = UIAction(
      title: String(localized: "All Professors", bundle: .module),
      image: UIImage(systemName: "person.2"),
      state: state.selectedProfessorID == nil ? .on : .off
    ) { _ in select?(nil) }
    let professors = state.professors.map { professor in
      UIAction(title: professor.name, state: professor.id == state.selectedProfessorID ? .on : .off) { _ in
        select?(professor.id)
      }
    }
    let selectedName = state.professors.first { $0.id == state.selectedProfessorID }?.name
    // Text rather than a symbol, since the name is the point.
    return UIBarButtonItem(
      title: selectedName ?? String(localized: "All Professors", bundle: .module),
      menu: UIMenu(children: [all, UIMenu(options: .displayInline, children: professors)])
    )
  }

  private func showReplaceAlert(for lecture: Lecture, conflicts: [String]) {
    let alert = UIAlertController(
      title: LectureReplacement.title,
      message: LectureReplacement.message(conflicts: conflicts),
      preferredStyle: .alert
    )
    alert.addAction(UIAlertAction(title: LectureReplacement.cancel, style: .cancel))
    alert.addAction(UIAlertAction(title: LectureReplacement.confirm, style: .destructive) { _ in
      session.addLecture(lecture, replacingConflicts: true)
    })
    host.controller?.present(alert, animated: true)
  }
}

/// A hosting controller, handed to the screen it hosts so the screen can set its navigation bar.
@MainActor
private final class HostedController {
  weak var controller: UIViewController?
}

/// The course page's professors and how to pick one, for the inspector's navigation bar.
struct InspectorProfessorMenu {
  var professors: [Professor]
  var selectedID: Int?
  var select: @MainActor (Int?) -> Void
}

extension View {
  /// The screen's inline navigation title, except in lecture search's inspector, which shows it in
  /// a navigation bar of its own: there a title set here would replace the search's.
  func lectureScreenTitle(_ title: String) -> some View {
    modifier(LectureScreenTitle(title: title))
  }
}

private struct LectureScreenTitle: ViewModifier {
  let title: String
  @Environment(\.isInLectureSearchInspector) private var isInInspector

  func body(content: Content) -> some View {
    if isInInspector {
      content
    } else {
      content
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
    }
  }
}

/// Keeps a navigation controller's screens in step with the inspector's routes, and the routes in
/// step with the screens when one is popped with the back button or a swipe.
private struct InspectorNavigationController: UIViewControllerRepresentable {
  let session: LectureSearchSession
  let routes: [LectureSearchRoute]

  func makeCoordinator() -> Coordinator {
    Coordinator()
  }

  func makeUIViewController(context: Context) -> UINavigationController {
    let navigationController = InspectorStackController()
    navigationController.delegate = context.coordinator
    if #available(iOS 27.1, *) {
      let coordinator = context.coordinator
      navigationController.registerForTraitChanges(UITraitCollection.systemTraitsAffectingVerticalBarEdge) {
        (controller: UINavigationController, _) in
        coordinator.updateSharesWindowBar(controller)
      }
    }
    return navigationController
  }

  func updateUIViewController(_ navigationController: UINavigationController, context: Context) {
    let coordinator = context.coordinator
    coordinator.session = session
    coordinator.updateSharesWindowBar(navigationController)
    // Sharing the window's vertical bar, the inspector has no bar of its own: even an empty one
    // reserves a place in the window's bar and insets the inspector's screens by its width.
    if navigationController.isNavigationBarHidden != session.sharesWindowBar {
      navigationController.setNavigationBarHidden(session.sharesWindowBar, animated: false)
    }
    let shown = coordinator.routes
    guard routes != shown else { return }

    var controllers: [UIViewController] = []
    for (index, route) in routes.enumerated() {
      if index < shown.count, shown[index] == route, index < navigationController.viewControllers.count {
        controllers.append(navigationController.viewControllers[index])
      } else {
        let host = HostedController()
        let controller = UIHostingController(
          rootView: InspectorScreen(session: session, route: route, isRoot: index == 0, host: host)
        )
        host.controller = controller
        controller.view.backgroundColor = .clear
        controllers.append(controller)
      }
    }
    // Animated only when a screen is pushed on top of the ones shown.
    let isPush = routes.count == shown.count + 1 && Array(routes.prefix(shown.count)) == shown && !shown.isEmpty
    coordinator.routes = routes
    navigationController.setViewControllers(controllers, animated: isPush)
  }

  @MainActor
  final class Coordinator: NSObject, UINavigationControllerDelegate {
    var session: LectureSearchSession?
    /// The routes of the screens in the navigation controller.
    var routes: [LectureSearchRoute] = []

    func updateSharesWindowBar(_ controller: UIViewController) {
      guard #available(iOS 27.1, *), let session else { return }
      let shares = controller.traitCollection.verticalBarEdge != .unspecified
      if session.sharesWindowBar != shares {
        session.sharesWindowBar = shares
      }
    }

    func navigationController(
      _ navigationController: UINavigationController,
      didShow viewController: UIViewController,
      animated: Bool
    ) {
      // A screen popped with the back button or a swipe.
      let count = navigationController.viewControllers.count
      guard count < routes.count, let session else { return }
      routes = Array(routes.prefix(count))
      session.inspectorPath = Array(routes.dropFirst())
    }
  }
}

/// The inspector's navigation controller, which gives its screens the pane's own safe area.
///
/// In a window with a vertical bar, as on iPhone Duo's inner display in landscape, a navigation
/// controller passes the bar's whole inset on to its screens even when it sits clear of the bar,
/// as the inspector does beside it. That inset is taken back off, so the screens are not left
/// with an empty strip the bar's width down their trailing side.
private final class InspectorStackController: UINavigationController {
  override func viewDidLayoutSubviews() {
    super.viewDidLayoutSubviews()
    for child in viewControllers {
      var additional = child.additionalSafeAreaInsets
      let inherited = child.view.safeAreaInsets
      let excessLeft = inherited.left - additional.left - view.safeAreaInsets.left
      let excessRight = inherited.right - additional.right - view.safeAreaInsets.right
      let left = excessLeft > 0 ? -excessLeft : 0
      let right = excessRight > 0 ? -excessRight : 0
      if additional.left != left || additional.right != right {
        additional.left = left
        additional.right = right
        child.additionalSafeAreaInsets = additional
      }
    }
  }
}

extension EnvironmentValues {
  /// Set on the screens of the full-screen lecture search's inspector.
  @Entry var isInLectureSearchInspector = false
  /// Set in the inspector, which shows the course page's professor picker in its navigation bar.
  @Entry var reportProfessorMenu: (@MainActor (InspectorProfessorMenu) -> Void)? = nil
}
