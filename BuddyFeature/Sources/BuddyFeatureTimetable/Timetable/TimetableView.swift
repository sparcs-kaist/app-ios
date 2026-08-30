//
//  TimetableView.swift
//  BuddyFeature
//
//  Created by Soongyu Kwon on 28/02/2026.
//

import Foundation
import SwiftUI
import BuddyDomain
import BuddyFeatureShared
import FirebaseAnalytics
import TimetableUI

public struct TimetableView: View {
  #if os(macOS)
  private enum InspectorPage: Equatable {
    case addLecture
    case lectureDetails
  }
  #endif

  @Bindable private var viewModel: TimetableViewModel

  @State private var selectedLecture: LectureItem? = nil
  @State private var showSearchSheet: Bool = false
  @State private var selectedDetent: PresentationDetent = .medium
  #if os(macOS)
  @State private var isInspectorPresented: Bool = false
  @State private var inspectorPage: InspectorPage = .lectureDetails
  #endif

  @Environment(\.colorScheme) private var colorScheme

  /// Keeps the grid usable on short (landscape) screens where `80%` of the
  /// available height would otherwise squash it.
  private static let minimumGridHeight: CGFloat = 500

  /// Width past which the supporting cards switch to a two-column layout. Driven
  /// by the actual available width (not the size class) so it also kicks in for
  /// iPhones in landscape, which report a compact horizontal size class.
  private static let twoColumnWidthThreshold: CGFloat = 600

  /// Wide timetable layouts retain a useful full-day overview even when their
  /// lectures occupy only a narrow portion of the day.
  private static let wideMinimumVisibleTimeRange = 540...1080

  public var body: some View {
    GeometryReader { reader in
      NavigationStack {
        ScrollView {
          content(
            gridHeight: max(reader.size.height * 0.8, Self.minimumGridHeight),
            isWide: reader.size.width > Self.twoColumnWidthThreshold
          )
          .padding()
        }
        .background {
          BackgroundGradientView(color: .pink)
            .ignoresSafeArea()
        }
        .navigationTitle(String(localized: "Timetable", bundle: .module))
        .toolbarTitleDisplayMode(.inlineLarge)
        .background(Color.systemGroupedBackground)
        .toolbar {
          #if os(macOS)
          ToolbarItem(placement: .topBarTrailing) {
            ControlGroup {
              Toggle(isOn: inspectorPageBinding(.addLecture)) {
                Label(String(localized: "Add Lecture", bundle: .module), systemImage: "square.badge.plus")
              }
              .toggleStyle(.button)
              .help(String(localized: "Add Lecture", bundle: .module))

              Toggle(isOn: inspectorPageBinding(.lectureDetails)) {
                Label(String(localized: "Information", bundle: .module), systemImage: "info.circle")
              }
              .toggleStyle(.button)
              .disabled(selectedLecture == nil)
              .help(String(localized: "Information", bundle: .module))
            }
            .controlGroupStyle(.navigation)
            .labelStyle(.iconOnly)
          }
          #else
          ToolbarItem(placement: .topBarTrailing) {
            Button(String(localized: "Add Lecture", bundle: .module), systemImage: "square.badge.plus") {
              showSearchSheet = true
            }
            .disabled(viewModel.selectedTimetableID == nil)
          }
          #endif
        }
        #if os(macOS)
        .inspector(isPresented: $isInspectorPresented) {
          Group {
            switch inspectorPage {
            case .addLecture:
              if viewModel.selectedTimetableID == nil {
                ContentUnavailableView(
                  "Cannot Add Lecture",
                  systemImage: "calendar.badge.exclamationmark",
                  description: Text("You cannot add a lecture to My Table.", bundle: .module)
                )
              } else {
                lectureSearch
              }
            case .lectureDetails:
              if let selectedLecture {
                VStack(spacing: 0) {
                  HStack {
                    Text(selectedLecture.lecture.name)
                      .font(.headline)
                      .lineLimit(1)

                    Spacer()
                  }
                  .padding()

                  Divider()

                  lectureDetail(for: selectedLecture, showsNavigationChrome: false)
                    .padding(.top)
                }
              } else {
                ContentUnavailableView(
                  "No Lecture Selected",
                  systemImage: "rectangle.rightthird.inset.filled",
                  description: Text("Select a lecture to view its details.", bundle: .module)
                )
              }
            }
          }
          .inspectorColumnWidth(min: 320, ideal: 420, max: 700)
        }
        #else
        .sheet(item: $selectedLecture) { (item: LectureItem) in
          NavigationStack {
            lectureDetail(for: item)
            .presentationDragIndicator(.visible)
            .presentationDetents([.medium, .large])
          }
          // The lecture search pushes this same screen, where a back button already
          // exists — so the close button belongs to the presentation, not the view.
          .sheetCloseButton { selectedLecture = nil }
        }
        #endif
        #if !os(macOS)
        .sheet(isPresented: $showSearchSheet) {
          lectureSearch
        }
        #endif
        .alert(
          viewModel.alertState?.title ?? String(localized: "Error", bundle: .module),
          isPresented: $viewModel.isAlertPresented,
          actions: {
            Button(String(localized: "Okay", bundle: .module), role: .close) { }
          }, message: {
            Text(viewModel.alertState?.message ?? String(localized: "Unexpected Error", bundle: .module))
          }
        )
        .analyticsScreen(name: "Timetable", class: String(describing: Self.self))
        #if os(macOS)
        .onChange(of: viewModel.selectedTimetableID) { _, _ in
          resetLectureInspector()
        }
        .onChange(of: viewModel.selectedSemester?.id) { _, _ in
          resetLectureInspector()
        }
        #endif
      }
    }
  }

  // MARK: - Layout

  @ViewBuilder
  private func content(gridHeight: CGFloat, isWide: Bool) -> some View {
    VStack(spacing: 28) {
      selector(isWide: isWide)
      if isWide {
        // Leverage the wider screen: lay the supporting cards out in two
        // columns instead of one long vertical scroll.
        HStack(alignment: .top, spacing: 28) {
					gridCard(height: gridHeight, isWide: true)
            .frame(maxWidth: .infinity)

          VStack(spacing: 28) {
						lectureListCard
            creditGraphCard
            summaryCard
          }
          .frame(maxWidth: .infinity)
        }
      } else {
				gridCard(height: gridHeight, isWide: false)
        lectureListCard
        creditGraphCard
        summaryCard
      }
    }
  }

  // MARK: - Cards

	private func selector(isWide: Bool) -> some View {
    CompactTimetableSelector(
      semesters: viewModel.semesters,
      selectedSemester: $viewModel.selectedSemester,
      timetables: viewModel.timetables,
      selectedTimetableID: $viewModel.selectedTimetableID,
      createTimetable: {
        await viewModel.createTable()
      },
      renameTimetable: { title in
        await viewModel.renameTable(title: title)
      },
      deleteTimetable: {
        await viewModel.deleteTable()
      },
			isWide: isWide
    )
    .redacted(reason: viewModel.isLoading ? .placeholder : [])
  }

  private func gridCard(height: CGFloat, isWide: Bool) -> some View {
    TimetableGrid(
      selectedTimetable: viewModel.timetableWithCandidate,
      candidateLecture: viewModel.candidateLecture,
      selectedLecture: { selectedLecture in
        selectLecture(selectedLecture)
      },
      onDelete: { lecture in
        Task {
          await viewModel.deleteLecture(lecture: lecture)
        }
      },
      placement: .view,
      minimumVisibleTimeRange: isWide ? Self.wideMinimumVisibleTimeRange : nil
    )
    .animation(nil, value: viewModel.selectedSemester)
    .timetableCardStyle()
    .frame(height: height)
  }

  private var lectureListCard: some View {
    LectureList(
      lectures: viewModel.timetable?.lectures,
      selectedLecture: { selectedLecture in
        selectLecture(selectedLecture)
      }
    )
    .timetableCardStyle()
  }

  private var creditGraphCard: some View {
    TimetableCreditGraph(selectedTimetable: viewModel.timetable)
      .timetableCardStyle()
  }

  private var summaryCard: some View {
    TimetableSummaryView(selectedTimetable: viewModel.timetable)
      .timetableCardStyle()
  }

  private var displayName: String {
    guard let timetable = selectedTimetable else {
      return String(localized: "My Table", bundle: .module)
    }
    return timetable.title.isEmpty ? String(localized: "Untitled", bundle: .module) : timetable.title
  }

  private var selectedTimetable: TimetableSummary? {
    viewModel.timetables.first(where: { $0.id == viewModel.selectedTimetableID })
  }

  @ViewBuilder
  private var lectureSearch: some View {
    if let selectedSemester = viewModel.selectedSemester {
      LectureSearchView(
        detent: $selectedDetent,
        timetableDisplayName: displayName,
        selectedSemester: selectedSemester,
        candidateLecture: $viewModel.candidateLecture,
        onAdd: { lecture in
          Task {
            await viewModel.addLecture(lecture: lecture)
          }
        },
        onClose: closeLectureSearch
      )
      .presentationDetents([.height(130), .medium, .large], selection: $selectedDetent)
      .onAppear {
        selectedDetent = .medium
      }
    }
  }

  private func lectureDetail(
    for item: LectureItem,
    showsNavigationChrome: Bool = true
  ) -> some View {
    LectureDetailView(
      lecture: item.lecture,
      onAdd: nil,
      isOverlapping: false,
      lectureClass: item.lectureClass,
      showsNavigationChrome: showsNavigationChrome
    )
  }

  #if os(macOS)
  private func selectLecture(_ lecture: LectureItem) {
    selectedLecture = lecture
    inspectorPage = .lectureDetails
    isInspectorPresented = true
  }

  private func inspectorPageBinding(_ page: InspectorPage) -> Binding<Bool> {
    Binding(
      get: {
        isInspectorPresented && inspectorPage == page
      },
      set: { isSelected in
        if isSelected {
          inspectorPage = page
          isInspectorPresented = true
        } else if inspectorPage == page {
          isInspectorPresented = false
        }
      }
    )
  }

  private func closeLectureSearch() {
    isInspectorPresented = false
  }

  private func resetLectureInspector() {
    selectedLecture = nil
  }
  #else
  private func selectLecture(_ lecture: LectureItem) {
    selectedLecture = lecture
  }

  private func closeLectureSearch() {
    showSearchSheet = false
  }
  #endif

  public init(_ viewModel: TimetableViewModel) {
    self.viewModel = viewModel
  }
}

// MARK: - Card Styling

private struct TimetableCardStyle: ViewModifier {
  @Environment(\.colorScheme) private var colorScheme

  func body(content: Content) -> some View {
    content
      .padding()
      .background(colorScheme == .light ? Color.secondarySystemGroupedBackground : .clear, in: .rect(cornerRadius: 28))
      .glassEffect(colorScheme == .light ? .identity : .regular, in: .rect(cornerRadius: 28))
  }
}

private extension View {
  /// The shared rounded, glass-backed card treatment used by every timetable section.
  func timetableCardStyle() -> some View {
    modifier(TimetableCardStyle())
  }
}
