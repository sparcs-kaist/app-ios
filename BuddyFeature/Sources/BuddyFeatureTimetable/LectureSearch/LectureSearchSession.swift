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
  /// Observed through its own properties; this only hands it to the search's screens.
  @ObservationIgnored let timetableViewModel: TimetableViewModel

  init(timetableViewModel: TimetableViewModel) {
    self.timetableViewModel = timetableViewModel
    self.preview = LectureSearchTimetablePreview(timetableViewModel: timetableViewModel)
  }

  var isInspectorPresented: Bool {
    isWide && inspectorRoot != nil
  }

  /// Shows a lecture or course in the inspector, in place of whatever it showed.
  func inspect(_ route: LectureSearchRoute) {
    inspectorPath = []
    inspectorRoot = route
  }

  func closeInspector() {
    inspectorRoot = nil
    inspectorPath = []
    timetableViewModel.candidateLecture = nil
  }

  /// Takes what the inspector shows out of it, root first, such as when the screen becomes too
  /// narrow for it and the screens are pushed instead.
  func takeInspectorRoutes() -> [LectureSearchRoute] {
    let routes = (inspectorRoot.map { [$0] } ?? []) + inspectorPath
    inspectorRoot = nil
    inspectorPath = []
    return routes
  }

  func addLecture(_ lecture: Lecture) {
    // Added from the inspector, the lecture is done with. Added from the results beside it, the
    // inspector may be showing something else, which stays.
    if inspectorRoot == .lecture(lecture) || inspectorPath.contains(.lecture(lecture)) {
      closeInspector()
    }
    Task {
      await timetableViewModel.addLecture(lecture: lecture)
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
    .inspectorColumnWidth(min: 320, ideal: Self.idealWidth, max: 440)
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
    .environment(\.reportProfessorMenu) { professorMenu = $0 }
    .wishlistErrorAlert(session.searchViewModel)
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
  }

  private var barState: BarState {
    switch route {
    case .lecture(let lecture):
      let timetable = session.timetableViewModel.timetable
      return BarState(
        title: lecture.name,
        isWishlisted: session.searchViewModel.isWishlisted(lecture),
        isAdded: timetable?.contains(lecture) ?? false,
        conflicts: timetable?.conflicts(with: lecture) ?? []
      )
    case .course(_, let name):
      return BarState(
        title: name,
        professors: professorMenu?.professors ?? [],
        selectedProfessorID: professorMenu?.selectedID
      )
    }
  }

  private func configureBar() {
    guard let navigationItem = host.controller?.navigationItem else { return }
    let state = barState
    navigationItem.title = state.title
    navigationItem.largeTitleDisplayMode = .never
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
        // Still tappable when it overlaps, so the alert can say why it cannot be added.
        if state.conflicts.isEmpty {
          session.addLecture(lecture)
        } else {
          showCannotAddAlert(conflicts: state.conflicts)
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

  private func showCannotAddAlert(conflicts: [String]) {
    let list = conflicts.formatted(.list(type: .and))
    let alert = UIAlertController(
      title: String(localized: "Cannot Add Lecture", bundle: .module),
      message: String(localized: "This lecture overlaps with \(list) in your timetable.", bundle: .module),
      preferredStyle: .alert
    )
    alert.addAction(UIAlertAction(title: String(localized: "Okay", bundle: .module), style: .cancel))
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
    let navigationController = UINavigationController()
    navigationController.delegate = context.coordinator
    return navigationController
  }

  func updateUIViewController(_ navigationController: UINavigationController, context: Context) {
    let coordinator = context.coordinator
    coordinator.session = session
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

extension EnvironmentValues {
  /// Set on the screens of the full-screen lecture search's inspector.
  @Entry var isInLectureSearchInspector = false
  /// Set in the inspector, which shows the course page's professor picker in its navigation bar.
  @Entry var reportProfessorMenu: (@MainActor (InspectorProfessorMenu) -> Void)? = nil
}
