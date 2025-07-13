//
//  TaxiChatListView.swift
//  soap
//
//  Created by Soongyu Kwon on 13/07/2025.
//

import SwiftUI

struct TaxiChatListView: View {
  @State private var viewModel = TaxiChatListViewModel()

  var body: some View {
    NavigationStack {
      LazyVStack {

      }
      .navigationTitle(Text("Chats"))
      .background(Color.secondarySystemBackground)
    }
  }
}


#Preview {
  TaxiChatListView()
}
