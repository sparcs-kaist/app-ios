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
  #endif

  @Namespace private var namespace

  private var feedViewModel: FeedViewModelProtocol
  private var boardListViewModel: BoardListViewModelProtocol

  init(feedViewModel: FeedViewModelProtocol = FeedViewModel(), boardListViewModel: BoardListViewModelProtocol = BoardListViewModel()) {
    self.feedViewModel = feedViewModel
    self.boardListViewModel = boardListViewModel
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
    .sheet(item: $viewModel.invitedRoom) { room in
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
  private var platformNavigation: some View {
    NavigationSplitView {
      List(selection: macOSTabSelection) {
        Label("Feed", systemImage: "text.rectangle.page")
          .tag(TabSelection.feed)
        Label("Boards", systemImage: "tray.full")
          .tag(TabSelection.board)
        Label("Timetable", systemImage: "square.grid.2x2")
          .tag(TabSelection.timetable)
        Label("Taxi", systemImage: "car")
          .tag(TabSelection.taxi)
        Label("Search", systemImage: "magnifyingglass")
          .tag(TabSelection.search)
      }
      .listStyle(.sidebar)
      .navigationTitle(String(localized: "Buddy"))
    } detail: {
      macOSDetail
    }
    .toolbarBackgroundVisibility(.hidden, for: .windowToolbar)
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
      NavigationStack(path: $boardListPath) {
        BoardListView(boardListViewModel, deepLinkedPost: $viewModel.deepLinkedPost)
      }
      .id(TabSelection.board)
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
      selectTab(.board)
      Task {
        await viewModel.resolvePost(id: id)
      }
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
  private var macOSTabSelection: Binding<TabSelection> {
    Binding(
      get: { selectedTab },
      set: { selectTab($0) }
    )
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
