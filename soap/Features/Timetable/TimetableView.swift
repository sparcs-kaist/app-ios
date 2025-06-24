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
        VStack(spacing: 0) {
          // Timetable Selector
          CompactTimetableSelector()
            .padding(.horizontal)
            .padding(.horizontal, 4)

          // Timetable Gird View
          TimetableGrid()
            .padding()
            .background(.background)
            .clipShape(.rect(cornerRadius: 28))
            .frame(height: .screenHeight * 0.55)
            .padding()

          // Timetable Summary View
          TimetableSummary()
            .padding()
            .background(.background)
            .clipShape(.rect(cornerRadius: 28))
        }
      }
      .navigationTitle("Timetable")
      .background(Color.secondarySystemBackground)
      .task {
        // fetch data
        await viewModel.fetchData()
      }
      .navigationTitle("Timetable")
    }
  }
}

#Preview {
  TimetableView()
    .environment(TimetableViewModel())
}
