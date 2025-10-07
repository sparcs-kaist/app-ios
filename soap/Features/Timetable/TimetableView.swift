//
//  TimetableView.swift
//  soap
//
//  Created by Soongyu Kwon on 30/10/2024.
//

import SwiftUI
import BuddyDomain

struct TimetableView: View {
  @State private var viewModel = TimetableViewModel()

  @State private var showSearchSheet: Bool = false
  @State private var selectedLecture: Lecture? = nil

  @State private var selectedDetent: PresentationDetent = .height(130)
  @FocusState private var isFocused: Bool

  @Environment(\.colorScheme) private var colorScheme

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
          .background(colorScheme == .light ? Color.secondarySystemGroupedBackground : .clear, in: .rect(cornerRadius: 28))
          .glassEffect(colorScheme == .light ? .identity : .regular, in: .rect(cornerRadius: 28))
          .frame(height: .screenHeight * 0.65)
          .environment(viewModel)

          TimetableCreditGraph()
            .padding()
            .background(colorScheme == .light ? Color.secondarySystemGroupedBackground : .clear, in: .rect(cornerRadius: 28))
            .glassEffect(colorScheme == .light ? .identity : .regular, in: .rect(cornerRadius: 28))
            .environment(viewModel)

          // Timetable Summary View
          TimetableSummary()
            .padding()
            .background(colorScheme == .light ? Color.secondarySystemGroupedBackground : .clear, in: .rect(cornerRadius: 28))
            .glassEffect(colorScheme == .light ? .identity : .regular, in: .rect(cornerRadius: 28))
            .environment(viewModel)
        }
        .padding()
      }
      .background {
        BackgroundGradientView(color: .pink)
          .ignoresSafeArea()
      }
      .navigationTitle("Timetable")
      .toolbarTitleDisplayMode(.inlineLarge)
      .background(Color.systemGroupedBackground)
      .toolbar {
        ToolbarItem(placement: .topBarTrailing) {
          Button("Add Lecture", systemImage: "plus") {
            showSearchSheet = true
          }
          .disabled(!viewModel.isEditable)
        }
      }
      .sheet(item: $selectedLecture) { (item: Lecture) in
        NavigationStack {
          LectureDetailView(lecture: item, onAdd: nil, isOverlapping: false)
            .presentationDragIndicator(.visible)
            .presentationDetents([.medium, .large])
        }
      }
      .sheet(isPresented: $showSearchSheet) {
        LectureSearchView(detent: $selectedDetent)
          .presentationDetents([.height(130), .medium, .large], selection: $selectedDetent)
          .environment(viewModel)
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
