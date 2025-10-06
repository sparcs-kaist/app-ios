//
//  ContentView.swift
//  WatchBuddy Watch App
//
//  Created by Soongyu Kwon on 04/10/2025.
//

import SwiftUI
import Factory
import BuddyDomain

struct ContentView: View {
  @AppStorage("timetableData") private var timetableData: Data = .init()

  private var timetable: Timetable? {
    guard !timetableData.isEmpty else { return nil }
    return try? JSONDecoder().decode(Timetable.self, from: timetableData)
  }

  var body: some View {
    Group {
      if let timetable {
        NavigationStack {
          
        }
      } else {
        Text("Please open Buddy app on your iPhone to sync your timetable for this semester.")
          .multilineTextAlignment(.center)
      }
    }
  }
}

#Preview {
  ContentView()
}

