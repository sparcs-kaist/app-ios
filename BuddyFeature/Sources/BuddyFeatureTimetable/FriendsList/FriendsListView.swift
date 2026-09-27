//
//  FriendsListView.swift
//  BuddyFeature
//
//  Created by Soongyu Kwon on 9/26/26.
//

import SwiftUI
import BuddyDomain

struct FriendsListView: View {
	var body: some View {
		VStack {
			Text("Hello")
		}
		.navigationTitle("Friends")
		.toolbarTitleDisplayMode(.inlineLarge)
		.toolbar {
			ToolbarItem(placement: .topBarTrailing) {
				Button("Add Friend", systemImage: "person.badge.plus") {
					
				}
			}
		}
	}
}

#Preview {
	NavigationStack {
		FriendsListView()
	}
}
