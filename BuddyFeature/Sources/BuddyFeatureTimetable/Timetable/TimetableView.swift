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
  @Bindable private var viewModel: TimetableViewModel

  @State private var selectedLecture: LectureItem? = nil
  @State private var showSearchSheet: Bool = false
  @State private var selectedDetent: PresentationDetent = .medium

  @Environment(\.colorScheme) private var colorScheme

  /// Keeps the grid usable on short (landscape) screens where `80%` of the
  /// available height would otherwise squash it.
  private static let minimumGridHeight: CGFloat = 500

  /// Width past which the supporting cards switch to a two-column layout. Driven
  /// by the actual available width (not the size class) so it also kicks in for
  /// iPhones in landscape, which report a compact horizontal size class.
  private static let twoColumnWidthThreshold: CGFloat = 600

  #if os(macOS)
  /// Height for the sheets this screen presents. Mac sheets size to their content, and
  /// neither of these two has a sensible one to give.
  private static let macOSSheetHeight: CGFloat = 750
  #endif

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
          ToolbarItem(placement: .topBarTrailing) {
            Button(String(localized: "Add Lecture", bundle: .module), systemImage: "square.badge.plus") {
              showSearchSheet = true
            }
            .disabled(viewModel.selectedTimetableID == nil)
          }
        }
        .sheet(item: $selectedLecture) { (item: LectureItem) in
          NavigationStack {
            LectureDetailView(
              lecture: item.lecture,
              onAdd: nil,
              isOverlapping: false,
              lectureClass: item.lectureClass
            )
            .presentationDragIndicator(.visible)
            .presentationDetents([.medium, .large])
          }
          #if os(macOS)
          // `presentationDetents` sizes nothing on a Mac — the sheet takes its content's
          // ideal height, and a lecture with reviews has no shortage of that, so it ran
          // to the bottom of the window. Cap it and let the scroll view do the rest.
          .frame(maxHeight: Self.macOSSheetHeight)
          #endif
          // The lecture search pushes this same screen, where a back button already
          // exists — so the close button belongs to the presentation, not the view.
          .sheetCloseButton { selectedLecture = nil }
        }
        .sheet(isPresented: $showSearchSheet) {
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
              }
            )
            .presentationDetents([.height(130), .medium, .large], selection: $selectedDetent)
            .onAppear {
              selectedDetent = .medium
            }
            #if os(macOS)
            // Same reason, opposite symptom: a `List` has no ideal height to offer, so
            // the sheet collapsed onto its own chrome and search results had nowhere to
            // land — which read as search being broken rather than invisible.
            .frame(height: Self.macOSSheetHeight)
            #endif
            // Known rough edge on macOS: this lands a row below the search field rather
            // than beside it. The field is drawn in a toolbar, which is a different
            // container from the content an overlay covers, and a toolbar item of our
            // own is silently dropped from a sheet (see `a57cb989`). A button a row low
            // still beats Escape being the only way out.
            .sheetCloseButton { showSearchSheet = false }
          }
        }
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
					gridCard(height: gridHeight)
            .frame(maxWidth: .infinity)

          VStack(spacing: 28) {
						lectureListCard
            creditGraphCard
            summaryCard
          }
          .frame(maxWidth: .infinity)
        }
      } else {
				gridCard(height: gridHeight)
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

  private func gridCard(height: CGFloat) -> some View {
    TimetableGrid(
      selectedTimetable: viewModel.timetableWithCandidate,
      candidateLecture: viewModel.candidateLecture,
      selectedLecture: { selectedLecture in
        self.selectedLecture = selectedLecture
      },
      onDelete: { lecture in
        Task {
          await viewModel.deleteLecture(lecture: lecture)
        }
      },
      placement: .view
    )
    .animation(nil, value: viewModel.selectedSemester)
    .timetableCardStyle()
    .frame(height: height)
  }

  private var lectureListCard: some View {
    LectureList(
      lectures: viewModel.timetable?.lectures,
      selectedLecture: { selectedLecture in
        self.selectedLecture = selectedLecture
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
