//
//  HomeView.swift
//  soap
//
//  Created by Soongyu Kwon on 12/06/2025.
//

import SwiftUI

struct HomeView: View {
  var body: some View {
    NavigationStack {
      ScrollView {
        Text("HomeView")
      }
      .border(.red)
      .navigationTitle(Text("Home"))
      .navigationBarTitleDisplayMode(.large)
    }
  }
}

#Preview {
  HomeView()
}
