//
//  MainView.swift
//  soap
//
//  Created by Soongyu Kwon on 12/06/2025.
//

import SwiftUI
import Observation
import Factory
import BuddyDomain
import BuddyFeatureTimetable
import BuddyFeatureFeed
import BuddyFeaturePost
import BuddyFeatureTaxi
import BuddyFeatureSearch
import MapKit

struct MainView: View {
  @State private var viewModel = MainViewModel()
  @State private var timetableViewModel = TimetableViewModel()
  // Held here, not inside the views, because the macOS detail column below renders
  // one tab at a time: a model owned by SearchView or TaxiListView would be rebuilt
  // on every tab switch, losing the query and the route filters with it. These have
  // to be `@State` rather than init properties — MainView is a struct and gets
  // re-initialised, which would hand the views a fresh instance each time.
  @State private var searchViewModel = SearchViewModel()
  @State private var taxiListViewModel: TaxiListViewModelProtocol = TaxiListViewModel()
  @State private var todayLecturesAccessoryViewModel = TodayLecturesAccessoryViewModel()
  @State private var extendTimetableView: Bool = false

  @State private var selectedTab: TabSelection = .feed

  @State private var feedPath = NavigationPath()
  @State private var boardListPath = NavigationPath()
  @State private var taxiPath = NavigationPath()
  @State private var searchPath = NavigationPath()

  #if os(macOS)
  @State private var retainedFeedPath = NavigationPath()
  @State private var retainedBoardListPath = NavigationPath()
  @State private var retainedTaxiPath = NavigationPath()
  @State private var retainedSearchPath = NavigationPath()

  /// The board whose posts the detail column is showing. Only meaningful while
  /// `selectedTab == .board`.
  @State private var selectedBoard: AraBoard?
  @State private var boardsNeedRetry: Bool = false
  #endif

  @Namespace private var namespace

  // Held as `@State` rather than plain init properties: `MainView` is a struct and
  // gets re-initialised whenever its parent re-renders, which would otherwise hand
  // the views a fresh view model and throw away the loaded feed and board list. The
  // macOS sidebar reads `boardListViewModel.state` directly, so that one in
  // particular has to survive.
  @State private var feedViewModel: FeedViewModelProtocol
  @State private var boardListViewModel: BoardListViewModelProtocol

  init(feedViewModel: FeedViewModelProtocol = FeedViewModel(), boardListViewModel: BoardListViewModelProtocol = BoardListViewModel()) {
    _feedViewModel = State(initialValue: feedViewModel)
    _boardListViewModel = State(initialValue: boardListViewModel)
  }

  var body: some View {
    platformNavigation
//    .tabViewBottomAccessory(isEnabled: isTabViewAccessoryEnabled) {
//      TimelineView(.animation(minimumInterval: 1)) { context in
//        TodayLecturesAccessoryView(context: context, viewModel: todayLecturesAccessoryViewModel)
//          .matchedTransitionSource(id: "TimetableViewSource", in: namespace)
//          .onTapGesture {
//            extendTimetableView = true
//          }
//      }
//
//    }
    .fullScreenCover(isPresented: $extendTimetableView) {
      TimetableView(timetableViewModel)
        .safeAreaInset(edge: .top) {
          Capsule()
            .fill(.primary.secondary)
            .frame(width: 36, height: 4)
        }
        #if os(iOS)  // zoom transitions / status bar are iOS-only
        .navigationTransition(.zoom(sourceID: "TimetableViewSource", in: namespace))
        #endif
    }
    .onOpenURL { url in
      guard let deepLink = DeepLink(url: url) else { return }
      handle(deepLink: deepLink)
    }
    .onReceive(NotificationCenter.default.publisher(for: .buddyInternalDeepLink)) { notification in
      guard let deepLink = notification.object as? DeepLink else { return }
      handle(deepLink: deepLink)
    }
    .dismissableCard(item: $viewModel.invitedRoom) { room in
      TaxiPreviewView(room: room)
        .presentationDragIndicator(.visible)
        .presentationDetents([.height(400), .height(500)])
    }
    .alert(viewModel.alertState?.title ?? "Error", isPresented: $viewModel.isAlertPresented) {
      Button(String(localized: "Okay"), role: .cancel) { }
    } message: {
      Text(viewModel.alertState?.message ?? "Unexpected Error")
    }
    .task {
//      await todayLecturesAccessoryViewModel.setup()
      await timetableViewModel.setup()
    }
  }

  #if os(iOS)
  private var platformNavigation: some View {
    TabView(selection: $selectedTab) {
      Tab("Feed", systemImage: "text.rectangle.page", value: .feed) {
        NavigationStack(path: $feedPath) {
          FeedView(feedViewModel)
        }
      }

      Tab("Boards", systemImage: "tray.full", value: .board) {
        NavigationStack(path: $boardListPath) {
          BoardListView(boardListViewModel, deepLinkedPost: $viewModel.deepLinkedPost)
        }
      }

//      if UIDevice.current.userInterfaceIdiom != .phone {
        Tab("Timetable", systemImage: "square.grid.2x2", value: .timetable) {
          TimetableView(timetableViewModel)
        }
//      }

//      Tab("Map", systemImage: "map", value: .map) {
//        Map()
//      }

      Tab("Taxi", systemImage: "car", value: .taxi) {
        NavigationStack(path: $taxiPath) {
          TaxiListView(viewModel: taxiListViewModel)
        }
      }

      Tab(value: .search, role: .search) {
        NavigationStack(path: $searchPath) {
          SearchView(searchViewModel)
        }
      }
    }
    .tabBarMinimizeBehavior(.onScrollDown)
    .tabViewStyle(.tabBarOnly)
  }
  #elseif os(macOS)
  /// A row in the macOS sidebar. Boards get a row each — the board-list screen iOS
  /// pushes through only exists to be tapped, and a sidebar can address the boards
  /// directly.
  private enum SidebarSelection: Hashable {
    case tab(TabSelection)
    case board(AraBoard)
  }

  private var platformNavigation: some View {
    NavigationSplitView {
      List(selection: sidebarSelection) {
				Label("Search", systemImage: "magnifyingglass")
					.tag(SidebarSelection.tab(.search))
        Label("Feed", systemImage: "text.rectangle.page")
          .tag(SidebarSelection.tab(.feed))
        Label("Timetable", systemImage: "square.grid.2x2")
          .tag(SidebarSelection.tab(.timetable))
        Label("Taxi", systemImage: "car")
          .tag(SidebarSelection.tab(.taxi))

        Section(String(localized: "Boards")) {
          boardRows
        }
      }
      .listStyle(.sidebar)
      .navigationTitle(String(localized: "Buddy"))
      // Deliberately the sidebar's own task, not part of the window-level one that
      // sets up the timetable, and separate again from the fetch the detail column
      // runs. Each region loads and fails on its own: boards that never arrive leave
      // the feed, timetable, taxi and search rows working, and a feed that will not
      // load says so in the detail column without emptying the sidebar.
			.task { await loadBoards() }
    } detail: {
      macOSDetail
    }
    .toolbarBackgroundVisibility(.hidden, for: .windowToolbar)
  }

  @ViewBuilder
  private var boardRows: some View {
    switch boardListViewModel.state {
    case .loading:
      if boardsNeedRetry {
        boardRetryRow
      } else {
        HStack(spacing: 8) {
          ProgressView()
            .controlSize(.small)
          Text("Loading…")
            .foregroundStyle(.secondary)
        }
      }
    case .loaded(let boards, let groups):
      ForEach(groups) { group in
        DisclosureGroup {
          ForEach(boards.filter { $0.group.id == group.id }) { board in
            Text(board.name.localized())
              .tag(SidebarSelection.board(board))
          }
        } label: {
          Label(group.name.localized(), systemImage: group.symbolName)
        }
      }
    case .error:
      boardRetryRow
    }
  }

  private var boardRetryRow: some View {
    Button(String(localized: "Try Again"), systemImage: "arrow.clockwise") {
      Task { await loadBoards() }
    }
    // `.plain` strips AppKit's push-button chrome so the row reads as a sidebar
    // item; it also strips the hit-test surface, hence the explicit shape.
    .buttonStyle(.plain)
    .contentShape(.rect)
  }

  private func loadBoards() async {
    if case .loaded = boardListViewModel.state { return }

    boardsNeedRetry = false
    await boardListViewModel.fetchBoards()

    // `fetchBoards()` returns without touching its state when it cannot resolve its
    // use case, and the state also stays `.loading` if the request never comes back
    // — which is what a pending keychain prompt does to every authenticated call.
    // Either way the sidebar would spin forever, so offer the retry instead.
    if case .loading = boardListViewModel.state {
      boardsNeedRetry = true
    }
  }

  @ViewBuilder
  private var macOSDetail: some View {
    switch selectedTab {
    case .feed:
      NavigationStack(path: $feedPath) {
        FeedView(feedViewModel)
      }
      .id(TabSelection.feed)
    case .board:
      if let selectedBoard {
        NavigationStack(path: $boardListPath) {
          PostListView(board: selectedBoard)
            // Carries over the deep-link destination `BoardListView` used to own.
            .navigationDestination(item: $viewModel.deepLinkedPost) { post in
              PostView(post: post)
            }
        }
        .id(selectedBoard.id)
      } else {
        ContentUnavailableView(
          String(localized: "Select a Board"),
          systemImage: "tray.full",
          description: Text("Pick a board from the sidebar to read its posts.")
        )
      }
    case .timetable:
      TimetableView(timetableViewModel)
    case .taxi:
      NavigationStack(path: $taxiPath) {
        TaxiListView(viewModel: taxiListViewModel)
      }
      .id(TabSelection.taxi)
    case .search:
      NavigationStack(path: $searchPath) {
        SearchView(searchViewModel)
      }
      .id(TabSelection.search)
    case .map:
      EmptyView()
    }
  }
  #endif

  private func handle(deepLink: DeepLink) {
    switch deepLink {
    case .taxiInvite(let code):
      selectTab(.taxi)
      Task {
        await viewModel.resolveInvite(code: code)
      }
    case .araPost(let id):
      #if os(macOS)
      // A board has to be selected before the detail column can present anything,
      // and which board that is only becomes known once the post is resolved.
      Task {
        await viewModel.resolvePost(id: id)
        guard let post = viewModel.deepLinkedPost else { return }
        if let board = post.board ?? selectedBoard ?? loadedBoards.first {
          select(board: board)
        }
      }
      #else
      selectTab(.board)
      Task {
        await viewModel.resolvePost(id: id)
      }
      #endif
    case .timetable:
      selectTab(.timetable)
    }
  }

  private func selectTab(_ tab: TabSelection) {
    guard tab != selectedTab else { return }

    #if os(macOS)
    retainPath(for: selectedTab)
    restorePath(for: tab)
    #endif

    selectedTab = tab
  }

  #if os(macOS)
  private var sidebarSelection: Binding<SidebarSelection?> {
    Binding(
      get: {
        if selectedTab == .board, let selectedBoard {
          return .board(selectedBoard)
        }
        return .tab(selectedTab)
      },
      set: { newValue in
        switch newValue {
        case .tab(let tab):
          selectedBoard = nil
          selectTab(tab)
        case .board(let board):
          select(board: board)
        case nil:
          break
        }
      }
    )
  }

  private func select(board: AraBoard) {
    // `selectTab` keeps one retained path per tab, not per board, so switching
    // boards has to clear it here. The detail column's `.id(board.id)` rebuilds the
    // stack view but `boardListPath` is our own state and would otherwise restore
    // the post that was open in the previous board.
    if board != selectedBoard {
      boardListPath = NavigationPath()
      retainedBoardListPath = NavigationPath()
    }
    selectedBoard = board
    selectTab(.board)
  }

  private var loadedBoards: [AraBoard] {
    if case .loaded(let boards, _) = boardListViewModel.state { return boards }
    return []
  }

  private var loadedGroups: [AraBoardGroup] {
    if case .loaded(_, let groups) = boardListViewModel.state { return groups }
    return []
  }

  private func retainPath(for tab: TabSelection) {
    switch tab {
    case .feed:
      retainedFeedPath = feedPath
    case .board:
      retainedBoardListPath = boardListPath
    case .taxi:
      retainedTaxiPath = taxiPath
    case .search:
      retainedSearchPath = searchPath
    case .map, .timetable:
      break
    }
  }

  private func restorePath(for tab: TabSelection) {
    switch tab {
    case .feed:
      feedPath = retainedFeedPath
    case .board:
      boardListPath = retainedBoardListPath
    case .taxi:
      taxiPath = retainedTaxiPath
    case .search:
      searchPath = retainedSearchPath
    case .map, .timetable:
      break
    }
  }
  #endif



  // Only read by the currently commented-out `tabViewBottomAccessory` above.
  #if os(iOS)
  private var isTabViewAccessoryEnabled: Bool {
    guard UIDevice.current.userInterfaceIdiom == .phone else { return false }
    switch selectedTab {
    case .feed:
      return feedPath.isEmpty
    case .board:
      return boardListPath.isEmpty
    case .taxi:
      return taxiPath.isEmpty
    case .search:
      return searchPath.isEmpty
    case .map:
      return true
    default:
      return false
    }
  }
  #endif
}

//#Preview {
//  MainView(feedViewModel: MockFeedViewModel(), boardListViewModel: MockBoardListViewModel())
//}
