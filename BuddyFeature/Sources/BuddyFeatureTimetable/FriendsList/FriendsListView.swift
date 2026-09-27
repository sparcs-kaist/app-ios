//
//  FriendsListView.swift
//  BuddyFeature
//
//  Created by Soongyu Kwon on 9/26/26.
//

import SwiftUI
import BuddyDomain

struct FriendsListView: View {
	@State private var showAddFriendsSheet = false

	@Namespace private var addFriendsTransition

	var body: some View {
		VStack {
			Text("Hello")
		}
		.navigationTitle("Friends")
		.toolbarTitleDisplayMode(.inlineLarge)
		.toolbar {
			ToolbarItem(placement: .topBarTrailing) {
				Button("Add Friend", systemImage: "person.badge.plus") {
					showAddFriendsSheet = true
				}
			}
			.matchedTransitionSource(id: "addFriends", in: addFriendsTransition)
		}
		.sheet(isPresented: $showAddFriendsSheet) {
			AddFriendsView()
				.navigationTransition(.zoom(sourceID: "addFriends", in: addFriendsTransition))
		}
	}
}

#Preview {
	NavigationStack {
		FriendsListView()
	}
}
