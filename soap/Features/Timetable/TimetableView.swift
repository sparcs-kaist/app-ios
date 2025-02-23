//
//  TimetableView.swift
//  soap
//
//  Created by Soongyu Kwon on 30/10/2024.
//

import SwiftUI
import BottomSheet

struct TimetableView: View {
  @Environment(TimetableViewModel.self) private var viewModel

  @State private var bottomSheetPosition: BottomSheetPosition = .relative(0.19)
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
    // Bottom Search Sheet
    .bottomSheet(bottomSheetPosition: $bottomSheetPosition, switchablePositions: [
      .relative(0.19),
      .relative(0.5),
      .relativeTop(0.975)
    ], headerContent: {
      HStack {
        Image(systemName: "magnifyingglass")
          .foregroundColor(Color(UIColor.secondaryLabel))
        TextField("Search by course title, instructor, etc.", text: $searchText)
          .focused($isFocused)
          .onChange(of: isFocused) {
            if isFocused {
              withAnimation {
                bottomSheetMoveToTop()
              }
            }
          }
      }
      .padding(.vertical, 8)
      .padding(.horizontal, 5)
      .background(
        RoundedRectangle(cornerRadius: 10)
          .fill(Color(UIColor.quaternarySystemFill))
      )
      .padding([.horizontal, .bottom])
    }) {
      // Bottom Sheet Content Area
      Text("Hello")
    }
    .enableAppleScrollBehavior()
    .customBackground(
      RoundedRectangle(cornerRadius: 16)
        .fill(Material.bar)
    )
    .customAnimation(.bouncy(duration: 0.3, extraBounce: -0.1))
  }

  private func bottomSheetMoveToTop() {
    bottomSheetPosition = .relativeTop(0.975)
  }
}

#Preview {
  NavigationStack {
    TimetableView()
      .environment(TimetableViewModel())
  }
}

