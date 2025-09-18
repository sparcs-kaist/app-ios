//
//  TimetableView.swift
//  soap
//
//  Created by Soongyu Kwon on 30/10/2024.
//

import SwiftUI

struct TimetableView: View {
  @State private var viewModel = TimetableViewModel()

  @State private var searchText: String = ""
  @State private var selectedLecture: Lecture? = nil
  @FocusState private var isFocused: Bool

  var body: some View {
    NavigationStack {
      ScrollView {
        VStack(spacing: 28) {
          // Timetable Selector
          CompactTimetableSelector()
            .environment(viewModel)

          // Timetable Gird View
          TimetableGrid() { lecture in
            selectedLecture = lecture
          }
          .padding()
          .background(.background)
          .clipShape(.rect(cornerRadius: 28))
          .frame(height: .screenHeight * 0.55)
          .environment(viewModel)

          // Timetable Summary View
          TimetableSummary()
            .padding()
            .background(.background)
            .clipShape(.rect(cornerRadius: 28))
            .environment(viewModel)
        }
        .padding()
      }
      .navigationTitle("Timetable")
      .toolbarTitleDisplayMode(.inlineLarge)
      .background(Color.secondarySystemBackground)
      .toolbar {
        ToolbarItem(placement: .topBarTrailing) {
          Button("Add Lecture", systemImage: "plus") { }
        }
      }
      .sheet(item: $selectedLecture) { (item: Lecture) in
        LectureDetailView(lecture: item)
          .presentationDragIndicator(.visible)
          .presentationDetents([.medium, .large])
      }
      .task {
        // fetch data
        await viewModel.fetchData()
      }
    }
  }
}

#Preview {
  TimetableView()
}
