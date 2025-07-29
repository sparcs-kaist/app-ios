//
//  AraBlockedUsersView.swift
//  soap
//
//  Created by 하정우 on 7/29/25.
//

import SwiftUI

struct AraBlockedUsersView: View {
  @State private var blockedUsers: [String]
  
  init(blockedUsers: [String]) {
    _blockedUsers = State(initialValue: blockedUsers)
  }
  
  var body: some View {
      List {
        ForEach(blockedUsers, id: \.self) {
          Text($0)
        }
        .onDelete { _ in
          // TODO: implement API call
        }
      }
    .navigationTitle("Blocked Users")
    .navigationBarTitleDisplayMode(.inline)
    .toolbar {
      EditButton()
    }
  }
}

#Preview {
  NavigationStack {
    AraBlockedUsersView(blockedUsers: ["Nickname 1", "Nickname 2"])
  }
}
