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
  @State private var todayLecturesAccessoryViewModel = TodayLecturesAccessoryViewModel()
  @State private var extendTimetableView: Bool = false

  @State private var selectedTab: TabSelection = .feed

  @State private var feedPath = NavigationPath()
  @State private var boardListPath = NavigationPath()
  @State private var taxiPath = NavigationPath()
  @State private var searchPath = NavigationPath()

  @Namespace private var namespace

  private var feedViewModel: FeedViewModelProtocol
  private var boardListViewModel: BoardListViewModelProtocol

  init(feedViewModel: FeedViewModelProtocol = FeedViewModel(), boardListViewModel: BoardListViewModelProtocol = BoardListViewModel()) {
    self.feedViewModel = feedViewModel
    self.boardListViewModel = boardListViewModel
  }

  var body: some View {
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
            .environment(\.timetableSiriTipIntent, NextClassAppIntents())
        }
//      }

//      Tab("Map", systemImage: "map", value: .map) {
//        Map()
//      }

      Tab("Taxi", systemImage: "car", value: .taxi) {
        NavigationStack(path: $taxiPath) {
          TaxiListView(roomToPreview: $viewModel.invitedRoom)
        }
      }

      Tab(value: .search, role: .search) {
        NavigationStack(path: $searchPath) {
          SearchView()
        }
      }
    }
    .tabBarMinimizeBehavior(.onScrollDown)
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
    .onOpenURL { url in
      guard let deepLink = DeepLink(url: url) else { return }
      handle(deepLink: deepLink)
    }
    .onReceive(NotificationCenter.default.publisher(for: .buddyInternalDeepLink)) { notification in
      guard let deepLink = notification.object as? DeepLink else { return }
      _ = PendingDeepLink.take()
      handle(deepLink: deepLink)
    }
    .onAppear {
      // Raised by an App Intent before this view existed, e.g. on a cold launch.
      if let deepLink = PendingDeepLink.take() { handle(deepLink: deepLink) }
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
    .tabViewStyle(.tabBarOnly)
  }

  private func handle(deepLink: DeepLink) {
    switch deepLink {
    case .taxiInvite(let code):
      // The Taxi tab presents the preview once the room arrives, as if it had been tapped there.
      selectedTab = .taxi
      taxiPath = NavigationPath()
      Task {
        await viewModel.resolveInvite(code: code)
      }
    case .araPost(let id):
      selectedTab = .board
      Task {
        await viewModel.resolvePost(id: id)
      }
    case .timetable:
      selectedTab = .timetable
    }
  }



  private var isTabViewAccessoryEnabled: Bool {
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
}

//#Preview {
//  MainView(feedViewModel: MockFeedViewModel(), boardListViewModel: MockBoardListViewModel())
//}
