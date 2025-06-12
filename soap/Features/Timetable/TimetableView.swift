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
    GeometryReader { geometry in
      ScrollView {
        VStack(spacing: 0) {
          // Timetable Selector
          CompactTimetableSelector()
            .padding(.horizontal)
            .padding(.horizontal, 4)
          //                            .padding(.leading)
          // Timetable Gird View
          ZStack {
            RoundedRectangle(cornerRadius: 16)
              .fill(.white)
            TimetableGrid()
              .padding(8)
          }
          .frame(height: geometry.size.height * 0.58)
          .padding([.horizontal, .bottom])
          .padding(.top, 8)

          // Timetable Summary View
          ZStack {
            RoundedRectangle(cornerRadius: 16)
              .fill(.white)
            TimetableSummary()
              .padding(8)
              .padding(.vertical, 8)
          }
          .padding(.horizontal)
        }
      }
      .navigationTitle("Timetable")
      .background(Color(UIColor.secondarySystemBackground))
      .ignoresSafeArea(.keyboard)
    }
    .task {
      // fetch data
      await viewModel.fetchData()
    }
  }
}

#Preview {
  NavigationStack {
    TimetableView()
      .environment(TimetableViewModel())
  }
}

