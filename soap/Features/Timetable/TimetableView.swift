//
//  TimetableView.swift
//  soap
//
//  Created by Soongyu Kwon on 30/10/2024.
//

import SwiftUI

struct TimetableView: View {
  @Environment(TimetableViewModel.self) private var viewModel

  @State private var searchText: String = ""
  @FocusState private var isFocused: Bool

  var body: some View {
    NavigationStack {
      ScrollView {
        VStack(spacing: 28) {
          // Timetable Selector
          CompactTimetableSelector()

          // Timetable Gird View
          TimetableGrid() { selectedLecture in
            viewModel.selectedLecture = selectedLecture
          }
            .padding()
            .background(.background)
            .clipShape(.rect(cornerRadius: 28))
            .frame(height: .screenHeight * 0.50)

          // Timetable Summary View
          TimetableSummary()
            .padding()
            .background(.background)
            .clipShape(.rect(cornerRadius: 28))
        }
        .padding()
      }
      .navigationTitle("Timetable")
      .background(Color.secondarySystemBackground)
      .toolbar {
        ToolbarItem(placement: .topBarTrailing) {
          Button("Add Lecture", systemImage: "plus") { }
        }
      }
      .sheet(item: Binding(
        get: { viewModel.selectedLecture },
        set: { viewModel.selectedLecture = $0 }
      )) { (item: Lecture) in
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
    .environment(TimetableViewModel())
}
