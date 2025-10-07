//
//  LectureTabView.swift
//  soap
//
//  Created by Soongyu Kwon on 06/10/2025.
//

import SwiftUI
import BuddyDomain
import BuddyDataMocks

struct LectureTabView: View {
  let items: [LectureItem]

  @State private var selection: UUID? = nil

  var body: some View {
    NavigationStack {
      if !items.isEmpty {
        TabView(selection: $selection) {
          ForEach(items) { item in
            LectureView(item: item)
              .containerBackground(item.lecture.backgroundColor.gradient, for: .tabView)
              .navigationTitle(item.lecture.classTimes[item.index].description)
              .tag(item.id)
          }
        }
        .tabViewStyle(.verticalPage)
        .onAppear {
          if let upcoming = defaultSelection() {
            selection = upcoming.id
          }
        }
      } else {
        Text("There is no class today.")
          .multilineTextAlignment(.center)
      }
    }
  }

  private func defaultSelection() -> LectureItem? {
    let now = Calendar.current.component(.hour, from: Date()) * 60 +
    Calendar.current.component(.minute, from: Date())

    // Look for the next class that starts after `now`
    if let next = items.first(where: { $0.lecture.classTimes[$0.index].begin >= now }) {
      return next
    }
    // Otherwise, fallback to the last one (probably already ongoing/just ended)
    return items.last
  }
}

#Preview {
  LectureTabView(items: Lecture.mockList.map { LectureItem(lecture: $0, index: 0) })
}
