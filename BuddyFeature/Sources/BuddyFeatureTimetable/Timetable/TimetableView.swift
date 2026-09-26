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
import UIKit

public struct TimetableView: View {
  @Bindable private var viewModel: TimetableViewModel

  @State private var editingActivity: TimetableActivity?
  @State private var sharedImage: TimetableShareImage?
  @State private var selectedLecture: LectureItem? = nil
  @State private var showSearchSheet: Bool = false
	@State private var showActivityCreationSheet: Bool = false
  @State private var selectedDetent: PresentationDetent = .medium
  /// Shared with the Credits screen, so its data loads once and grade edits show here too.
  @State private var creditViewModel = CreditCalculationViewModel()
  @State private var showsCredits = false
  @Namespace private var creditsTransition

  @Environment(\.colorScheme) private var colorScheme
  @Environment(\.scenePhase) private var scenePhase

  /// Keeps the grid usable on short (landscape) screens where `80%` of the
  /// available height would otherwise squash it.
  private static let minimumGridHeight: CGFloat = 500

  public var body: some View {
    GeometryReader { reader in
      NavigationStack {
        ScrollView {
          content(
            gridHeight: max(reader.size.height * 0.8, Self.minimumGridHeight),
            isWide: reader.size.width > LayoutMetrics.twoColumnWidthThreshold
          )
          .padding()
        }
        .refreshable { await viewModel.refresh() }
        .background {
          BackgroundGradientView(color: .pink)
            .ignoresSafeArea()
        }
        .navigationTitle(String(localized: "Timetable", bundle: .module))
        .toolbarTitleDisplayMode(.inlineLarge)
        .background(Color.systemGroupedBackground)
        .toolbar {
          ToolbarItem(placement: .topBarTrailing) {
						Menu("Add Event", systemImage: "square.badge.plus") {
							Button(String(localized: "Add Lecture", bundle: .module), systemImage: "book.badge.plus") {
								showSearchSheet = true
							}
							
							Button(String(localized: "New Activity", bundle: .module), systemImage: "calendar.badge.plus") {
								showActivityCreationSheet = true
							}
						}
						.disabled(viewModel.isReadOnly || viewModel.selectedTimetableID == nil || viewModel.timetable?.id != viewModel.selectedTimetableID.map(String.init))
          }
        }
        .navigationDestination(isPresented: $showsCredits) {
          CreditCalculationView(viewModel: creditViewModel)
            .navigationTransition(.zoom(sourceID: CreditsSummaryCard.transitionID, in: creditsTransition))
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
          }
        }
				.sheet(isPresented: $showActivityCreationSheet) {
					activityEditor()
						.presentationDragIndicator(.visible)
				}
        .sheet(item: $editingActivity) { activity in
          activityEditor(activity: activity)
            .presentationDragIndicator(.visible)
        }
        .sheet(item: $sharedImage) { item in
          ActivityView(
            activityItems: [item.source],
            applicationActivities: [InstagramStoryActivity(
              appID: Constants.metaAppID,
              backgroundColorHex: item.backgroundColorHex
            )]
          )
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
    .timetableThemeFromSettings()
    .task { await viewModel.observeConnectivity() }
    .onChange(of: scenePhase) { _, phase in
      if phase == .active { Task { await viewModel.refresh() } }
    }
  }

  // MARK: - Layout

  @ViewBuilder
  private func content(gridHeight: CGFloat, isWide: Bool) -> some View {
    VStack(spacing: 28) {
      selector(isWide: isWide)
      if viewModel.showsSavedStatus || viewModel.loadError != nil {
        offlineStatus
      }
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

      // At the very bottom, full width in both layouts.
      CreditsSummaryCard(
        gpa: creditViewModel.overallSummary.gpa,
        earnedCredits: creditViewModel.overallSummary.earnedCredits,
        graduationCredits: creditViewModel.requirements.graduation,
        isReady: creditViewModel.isOverallSummaryReady,
        isEnabled: creditViewModel.state != .loading,
        namespace: creditsTransition,
        onTap: { showsCredits = true }
      )
      // Loads the first time the card scrolls into view, not when the screen opens:
      // it fetches every semester. `load()` ignores repeat calls.
      .onScrollVisibilityChange(threshold: 0.1) { isVisible in
        if isVisible { Task { await creditViewModel.load() } }
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
      duplicateMyTable: {
        await viewModel.duplicateMyTable()
      },
      isDuplicatingMyTable: viewModel.isDuplicatingTable,
      renameTimetable: { title in
        await viewModel.renameTable(title: title)
      },
      deleteTimetable: {
        await viewModel.deleteTable()
      },
      shareTimetable: shareTimetable,
      canShareTimetable: viewModel.selectedSemester != nil && viewModel.timetable != nil,
			isWide: isWide,
      isReadOnly: viewModel.isReadOnly
    )
    .redacted(reason: viewModel.isLoading ? .placeholder : [])
  }

  private func gridCard(height: CGFloat) -> some View {
    ThemedGridCard {
      TimetableGrid(
        selectedTimetable: viewModel.timetableWithCandidate,
        candidateLecture: viewModel.candidateLecture,
        selectedLecture: { selectedLecture in
          self.selectedLecture = selectedLecture
        },
        onDelete: viewModel.isReadOnly ? nil : { lecture in
          Task {
            await viewModel.deleteLecture(lecture: lecture)
          }
        },
        onEditActivity: viewModel.isReadOnly || viewModel.selectedTimetableID == nil ? nil : { editingActivity = $0 },
        onDeleteActivity: viewModel.isReadOnly || viewModel.selectedTimetableID == nil ? nil : { activity in
          Task { await viewModel.deleteActivity(activity) }
        },
        placement: .view
      )
      .animation(nil, value: viewModel.selectedSemester)
    }
    .frame(height: height)
  }

  @ViewBuilder
  private func activityEditor(activity: TimetableActivity? = nil) -> some View {
    if let id = viewModel.selectedTimetableID, viewModel.timetable?.id == String(id) {
      ActivityCreationView(
        timetable: viewModel.timetable, timetableTitle: displayName, activity: activity,
        onSave: viewModel.isReadOnly ? nil : { draft in try await viewModel.saveActivity(timetableID: id, activityID: activity?.id, draft: draft) },
        onRefresh: { try await viewModel.refreshActivities(timetableID: id) }
      )
    }
  }

  private var offlineStatus: some View {
    HStack(alignment: .top) {
      Image(systemName: viewModel.isOffline ? "wifi.slash" : "clock.arrow.circlepath")
      VStack(alignment: .leading, spacing: 4) {
        Text(viewModel.isOffline
          ? String(localized: "Offline", bundle: .module)
          : String(localized: "Showing saved information", bundle: .module))
          .fontWeight(.medium)
        if let error = viewModel.loadError {
          Text(error)
        } else if let date = viewModel.lastUpdated {
          Text("Last updated \(date.formatted(date: .abbreviated, time: .shortened))", bundle: .module)
        }
      }
      Spacer()
      Button(String(localized: "Retry", bundle: .module)) {
        Task { await viewModel.refresh() }
      }
    }
    .font(.footnote)
    .foregroundStyle(.secondary)
    .frame(maxWidth: .infinity, alignment: .leading)
    .accessibilityElement(children: .contain)
  }

  private var lectureListCard: some View {
    LectureList(
      lectures: viewModel.timetable?.lectures,
      activities: viewModel.timetable?.activities,
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
      if let id = viewModel.selectedTimetableID {
        return String(localized: "Timetable \(id)", bundle: .module)
      }
      return String(localized: "My Table", bundle: .module)
    }
    return timetable.title.isEmpty ? String(localized: "Untitled", bundle: .module) : timetable.title
  }

  private func shareTimetable() {
    guard let semester = viewModel.selectedSemester, let timetable = viewModel.timetable else { return }
    let theme = TimetableThemeStore().selectedTheme
    // Themes without a background use the light system background for exports.
    let backgroundColorHex = theme.backgroundColorHex ?? "F2F2F7"

    // Render a separate view so the exported image excludes editing controls
    // and any lecture that is only being previewed in search.
    let renderer = ImageRenderer(content:
      TimetableShareRenderingView(semester: semester, timetable: timetable)
        .timetableTheme(theme)
        .environment(\.colorScheme, .light)
    )
    renderer.scale = 3
    renderer.isOpaque = false

    do {
      guard let stickerImage = renderer.uiImage else { throw CocoaError(.fileWriteUnknown) }
      // Give regular image exports a visible theme-colored border. Instagram
      // receives the original transparent sticker without this extra padding.
      let padding: CGFloat = 24
      let imageSize = CGSize(
        width: stickerImage.size.width + padding * 2,
        height: stickerImage.size.height + padding * 2
      )
      let format = UIGraphicsImageRendererFormat()
      format.scale = stickerImage.scale
      format.opaque = true
      let image = UIGraphicsImageRenderer(size: imageSize, format: format).image { context in
        let bounds = CGRect(origin: .zero, size: imageSize)
        UIColor(Color(hex: backgroundColorHex)).setFill()
        context.fill(bounds)
        stickerImage.draw(in: CGRect(origin: CGPoint(x: padding, y: padding), size: stickerImage.size))
      }
      let title = "\(semester.description) - \(displayName)"
      let source = try ImageActivityItemSource(image: image, title: title, instagramStoryImage: stickerImage)
      sharedImage = TimetableShareImage(source: source, backgroundColorHex: backgroundColorHex)
    } catch {
      viewModel.alertState = AlertState(
        title: String(localized: "Error", bundle: .module),
        message: String(localized: "Unable to create the timetable image. Please try again.", bundle: .module)
      )
      viewModel.isAlertPresented = true
    }
  }

  private var selectedTimetable: TimetableSummary? {
    viewModel.timetables.first(where: { $0.id == viewModel.selectedTimetableID })
  }

  public init(_ viewModel: TimetableViewModel) {
    self.viewModel = viewModel
  }
}

private struct TimetableShareImage: Identifiable {
  let id = UUID()
  let source: ImageActivityItemSource
  let backgroundColorHex: String
}

// MARK: - Card Styling

/// The grid's card. A separate view because `TimetableView` injects the theme on
/// its own body, and a view never observes environment values it sets there.
/// A theme that opts into a background replaces the card's usual fill and glass.
public struct ThemedGridCard<Content: View>: View {
  @Environment(\.timetableTheme) private var theme
  @ViewBuilder let content: Content

  public var body: some View {
    if let background = theme.backgroundColor {
      content
        .padding()
        .background(background, in: .rect(cornerRadius: 28))
    } else {
      content
        .timetableCardStyle()
    }
  }
}

private struct TimetableCardStyle: ViewModifier {
  @Environment(\.colorScheme) private var colorScheme

  func body(content: Content) -> some View {
    content
      .padding()
      .background(colorScheme == .light ? Color.secondarySystemGroupedBackground : .clear, in: .rect(cornerRadius: 28))
      .glassEffect(colorScheme == .light ? .identity : .regular, in: .rect(cornerRadius: 28))
  }
}

extension View {
  /// The shared rounded, glass-backed card treatment used by every timetable section.
  func timetableCardStyle() -> some View {
    modifier(TimetableCardStyle())
  }
}
