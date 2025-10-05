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

  var body: some View {
    NavigationStack {
      TabView {
        ForEach(items) { item in
          LectureView(item: item)
            .containerBackground(item.lecture.backgroundColor.gradient, for: .tabView)
            .navigationTitle(item.lecture.classTimes[item.index].description)
        }
      }
      .tabViewStyle(.verticalPage)
      .toolbar {
        ToolbarItem(placement: .topBarLeading) {
          Button("Timetable", systemImage: "calendar") { }
        }
      }
    }
  }
}

#Preview {
  LectureTabView(items: Lecture.mockList.map { LectureItem(lecture: $0, index: 0) })
}
