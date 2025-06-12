//
//  BoardListView.swift
//  soap
//
//  Created by Soongyu Kwon on 03/06/2025.
//

import SwiftUI

struct BoardListView: View {
  @State private var isExpanded1 = true
  var body: some View {
    NavigationStack {
      List {
        Section(header: Label("Notice", systemImage: "bell.badge.fill")) {
          NavigationLink("Portal Notice", destination: { })
          NavigationLink("Staff Notice", destination: { })
          NavigationLink("Facility Notice", destination: { })
          NavigationLink("External Company Advertisement", destination: { })
        }
        .headerProminence(.increased)

        Section(header: Label("Talk", systemImage: "text.bubble.fill")) {
          NavigationLink("General", destination: { })
        }
        .headerProminence(.increased)

        Section(header: Label("Orgarnisations and Clubs", systemImage: "person.2.circle.fill")) {
          NavigationLink("Students Group", destination: { })
          NavigationLink("Club", destination: { })
        }
        .headerProminence(.increased)

        Section(header: Label("Trade", systemImage: "tag.fill")) {
          NavigationLink("Wanted", destination: { })
          NavigationLink("Market", destination: { })
          NavigationLink("Real Estate", destination: { })
        }
        .headerProminence(.increased)

        Section(header: Label("Communication", systemImage: "envelope.open.fill")) {
          NavigationLink("Facility Feedback", destination: { })
          NavigationLink("Ara Feedback", destination: { })
          NavigationLink("Messages to the School", destination: { })
          NavigationLink("KAIST News", destination: { })
        }
        .headerProminence(.increased)
      }
      .listStyle(.sidebar)
      .navigationTitle("Boards")
    }
  }
}


#Preview {
  BoardListView()
}
