//
//  TimetableView.swift
//  soap
//
//  Created by Soongyu Kwon on 30/10/2024.
//

import SwiftUI
import BuddyDomain
import AppIntents

struct TimetableView: View {
  @State private var viewModel = TimetableViewModel()

  @State private var showSearchSheet: Bool = false
  @State private var selectedLecture: LectureItem? = nil

  @State private var selectedDetent: PresentationDetent = .medium
  @FocusState private var isFocused: Bool

  @Environment(\.colorScheme) private var colorScheme
  @Environment(\.horizontalSizeClass) private var horizontalSizeClass

  @AppStorage("NextClassAppIntentsSuggestion") private var siriSuggestion: Bool = true

  var body: some View {
    GeometryReader { proxy in
      NavigationStack {
        ScrollView {
          VStack(spacing: 28) {
            SiriTipView(intent: NextClassAppIntents(), isVisible: $siriSuggestion)

            // Timetable Selector
            CompactTimetableSelector()
              .environment(viewModel)

            // Timetable Gird View
            TimetableGrid() { lectureItem in
              selectedLecture = lectureItem
            }
            .padding()
            .background(colorScheme == .light ? Color.secondarySystemGroupedBackground : .clear, in: .rect(cornerRadius: 28))
            .glassEffect(colorScheme == .light ? .identity : .regular, in: .rect(cornerRadius: 28))
            .frame(height: proxy.size.height * 0.8)
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
        .navigationTitle(horizontalSizeClass == .compact ? String(localized: "Timetable") : "")
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
        .sheet(item: $selectedLecture) { (item: LectureItem) in
          NavigationStack {
            LectureDetailView(
              lecture: item.lecture,
              onAdd: nil,
              isOverlapping: false,
              classTime: item.lecture.classTimes[item.index]
            )
              .presentationDragIndicator(.visible)
              .presentationDetents([.medium, .large])
          }
        }
        .sheet(isPresented: $showSearchSheet) {
          LectureSearchView(detent: $selectedDetent)
            .presentationDetents([.height(130), .medium, .large], selection: $selectedDetent)
            .environment(viewModel)
            .onAppear {
              selectedDetent = .medium
            }
        }
        .task {
          // fetch data
          await viewModel.fetchData()
        }
      }
    }
  }
}

#Preview {
  TimetableView()
}
