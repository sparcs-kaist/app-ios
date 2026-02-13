//
//  MainView.swift
//  soap
//
//  Created by Soongyu Kwon on 12/06/2025.
//

import SwiftUI
import BuddyDomain
import BuddyFeatureTimetable
import BuddyFeatureFeed
import BuddyFeaturePost
import BuddyFeatureTaxi
import BuddyFeatureSearch

struct MainView: View {
  @State private var viewModel = MainViewModel()
  @State private var selectedTab: TabSelection = .feed

  private var feedViewModel: FeedViewModelProtocol
  private var boardListViewModel: BoardListViewModelProtocol

  init(feedViewModel: FeedViewModelProtocol = FeedViewModel(), boardListViewModel: BoardListViewModelProtocol = BoardListViewModel()) {
    self.feedViewModel = feedViewModel
    self.boardListViewModel = boardListViewModel
  }

  var body: some View {
    TabView(selection: $selectedTab) {
      Tab("Feed", systemImage: "text.rectangle.page", value: .feed) {
        FeedView(feedViewModel)
      }

      Tab("Boards", systemImage: "tray.full", value: .board) {
        BoardListView(boardListViewModel)
      }

      Tab("Timetable", systemImage: "square.grid.2x2", value: .timetable) {
        TimetableView()
      }

      Tab("Taxi", systemImage: "car", value: .taxi) {
        TaxiListView()
      }

      Tab(value: .search, role: .search) {
        SearchView()
      }
    }
    .tabBarMinimizeBehavior(.onScrollDown)
    .onOpenURL { url in
      guard let deepLink = DeepLink(url: url) else { return }
      switch deepLink {
      case .taxiInvite(let code):
        selectedTab = .taxi
        Task {
          await viewModel.resolveInvite(code: code)
        }
      case .araPost(let id):
        selectedTab = .board
        Task {
          await viewModel.resolvePost(id: id)
        }
      }
    }
    .sheet(item: $viewModel.invitedRoom) { room in
      TaxiPreviewView(room: room)
        .presentationDragIndicator(.visible)
        .presentationDetents([.height(400), .height(500)])
    }
    .sheet(item: $viewModel.deepLinkedPost) { post in
      NavigationStack {
        PostView(post: post)
          .navigationBarTitleDisplayMode(.inline)
      }
      .presentationDragIndicator(.visible)
    }
    .alert("Invalid Invitation", isPresented: $viewModel.showInvalidInviteAlert) {
      Button("Okay", role: .cancel) { }
    } message: {
      Text("The link you followed is invalid. Please try again.")
    }
    .alert("Post Not Found", isPresented: $viewModel.showInvalidPostAlert) {
      Button("Okay", role: .cancel) { }
    } message: {
      Text("The post you are looking for could not be found.")
    }
    .tabViewStyle(.tabBarOnly)
  }
}

//#Preview {
//  MainView(feedViewModel: MockFeedViewModel(), boardListViewModel: MockBoardListViewModel())
//}
