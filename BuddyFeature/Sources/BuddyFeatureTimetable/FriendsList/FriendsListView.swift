//
//  FriendsListView.swift
//  BuddyFeature
//
//  Created by Soongyu Kwon on 9/26/26.
//

import SwiftUI
import BuddyDomain
import FirebaseAnalytics

struct FriendsListView: View {
  @State private var viewModel = FriendsListViewModel()

  @State private var showAddFriendsSheet = false

  @Namespace private var addFriendsTransition

  var body: some View {
    content
      .navigationTitle(Text("Friends", bundle: .module))
      .toolbarTitleDisplayMode(.inlineLarge)
      .toolbar {
        ToolbarItem(placement: .topBarTrailing) {
          Button {
            showAddFriendsSheet = true
          } label: {
            Label {
              Text("Add Friend", bundle: .module)
            } icon: {
              Image(systemName: "person.badge.plus")
            }
          }
        }
        .matchedTransitionSource(id: "addFriends", in: addFriendsTransition)
      }
      .navigationDestination(for: Friend.self) { friend in
        FriendTimetableView(friend: friend)
      }
      .sheet(isPresented: $showAddFriendsSheet) {
        AddFriendsView(viewModel: viewModel)
          .navigationTransition(.zoom(sourceID: "addFriends", in: addFriendsTransition))
      }
      .alert(item: $viewModel.alertState) { state in
        Alert(
          title: Text(state.title),
          message: Text(state.message),
          dismissButton: .default(Text("OK", bundle: .module))
        )
      }
      .task {
        await viewModel.load()
        await viewModel.loadMyCode()
      }
      .analyticsScreen(name: "Friends", class: String(describing: Self.self))
  }

  @ViewBuilder
  private var content: some View {
    switch viewModel.viewState {
    case .loading:
      ProgressView()
        .frame(maxWidth: .infinity, maxHeight: .infinity)

    case .empty:
      ContentUnavailableView {
        Label {
          Text("No Friends Yet", bundle: .module)
        } icon: {
          Image(systemName: "person.2")
        }
      } description: {
        Text("Add a friend with their code to see them here.", bundle: .module)
      } actions: {
        Button {
          showAddFriendsSheet = true
        } label: {
          Text("Add Friend", bundle: .module)
        }
      }

    case .loaded(let friends):
      List {
        ForEach(friends) { friend in
          NavigationLink(value: friend) {
            FriendRow(friend: friend)
          }
          .swipeActions(edge: .leading, allowsFullSwipe: true) {
            Button {
              Task { await viewModel.toggleFavorite(friend) }
            } label: {
              if friend.isFavorite {
                Label {
                  Text("Unfavorite", bundle: .module)
                } icon: {
                  Image(systemName: "star.slash")
                }
              } else {
                Label {
                  Text("Favorite", bundle: .module)
                } icon: {
                  Image(systemName: "star")
                }
              }
            }
            .tint(.yellow)
          }
          .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            Button(role: .destructive) {
              Task { await viewModel.delete(friend) }
            } label: {
              Label {
                Text("Delete", bundle: .module)
              } icon: {
                Image(systemName: "trash")
              }
            }
          }
          .contextMenu {
            Button {
              Task { await viewModel.toggleFavorite(friend) }
            } label: {
              if friend.isFavorite {
                Label {
                  Text("Unfavorite", bundle: .module)
                } icon: {
                  Image(systemName: "star.slash")
                }
              } else {
                Label {
                  Text("Favorite", bundle: .module)
                } icon: {
                  Image(systemName: "star")
                }
              }
            }
            Button(role: .destructive) {
              Task { await viewModel.delete(friend) }
            } label: {
              Label {
                Text("Delete", bundle: .module)
              } icon: {
                Image(systemName: "trash")
              }
            }
          }
        }
      }
      .refreshable {
        await viewModel.load()
      }

    case .error(let message):
      ContentUnavailableView {
        Label {
          Text("Couldn’t Load Friends", bundle: .module)
        } icon: {
          Image(systemName: "exclamationmark.triangle")
        }
      } description: {
        Text(message)
      } actions: {
        Button {
          Task { await viewModel.load() }
        } label: {
          Text("Try Again", bundle: .module)
        }
      }
    }
  }
}

private struct FriendRow: View {
  let friend: Friend

  var body: some View {
    HStack(spacing: 12) {
      ZStack(alignment: .bottomTrailing) {
        Image(systemName: "person.crop.circle.fill")
          .font(.system(size: 36))
          .foregroundStyle(.tertiary)

        if friend.hasScheduleNow {
          Circle()
            .fill(.green)
            .frame(width: 12, height: 12)
            .overlay(
              Circle().stroke(Color.systemGroupedBackground, lineWidth: 2)
            )
        }
      }

      VStack(alignment: .leading, spacing: 2) {
        Text(friend.name)
          .font(.body)
          .foregroundStyle(.primary)

        if friend.hasScheduleNow {
          Text("In class now", bundle: .module)
            .font(.caption)
            .foregroundStyle(.secondary)
        }
      }

      Spacer()

      if friend.isFavorite {
        Image(systemName: "star.fill")
          .font(.footnote)
          .foregroundStyle(.yellow)
      }
    }
    .padding(.vertical, 4)
  }
}

#Preview {
  NavigationStack {
    FriendsListView()
  }
}
