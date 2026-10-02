//
//  LectureSearchTimetablePreview.swift
//  BuddyFeature
//
//  Created by Soongyu Kwon on 02/10/2026.
//

import SwiftUI
import BuddyDomain
import BuddyFeatureShared
import TimetableUI

/// The timetable preview of the full-screen lecture search: one card over the search's navigation
/// stack, the same view on every screen of the search, shown and hidden with a Timetable button in
/// each screen's toolbar. Screens leave room for it at their top.
@MainActor
@Observable
final class LectureSearchTimetablePreview {
  var isExpanded = false
  /// The height chosen with the handle, which screens leave room for; `nil` until then, for a
  /// default that suits the screen.
  var height: CGFloat?
  /// The height while the handle is dragged. Screens catch up when the drag ends, so a drag
  /// only resizes the card.
  var dragHeight: CGFloat?
  /// The height of the screens showing the card, last measured.
  var containerHeight: CGFloat = 0
  /// Where screens' room for the card begins, in global coordinates.
  var cardTop: CGFloat = 0
  /// The screens of the search on screen now that show the card.
  var screens: Set<UUID> = []
  /// Set while a screen without the card, such as the department picker, covers the search.
  var isCovered = false
  /// Observed through its own properties; this only hands it to the card.
  @ObservationIgnored let timetableViewModel: TimetableViewModel

  init(timetableViewModel: TimetableViewModel) {
    self.timetableViewModel = timetableViewModel
  }

  var isShown: Bool {
    isExpanded && !isCovered && !screens.isEmpty && containerHeight > 0 && cardTop > 0
  }

  /// The height screens leave room for.
  var restingHeight: CGFloat {
    clamped(height ?? containerHeight * 0.42)
  }

  /// The card's height, following the handle while it is dragged.
  var displayedHeight: CGFloat {
    dragHeight ?? restingHeight
  }

  /// Whether there is room to resize, which a phone in landscape lacks.
  var isResizable: Bool {
    largestHeight > Self.minimumHeight
  }

  func clamped(_ height: CGFloat) -> CGFloat {
    min(max(height, Self.minimumHeight), largestHeight)
  }

  /// Leaves room below for the search's filters and field and a couple of results.
  private var largestHeight: CGFloat {
    max(Self.minimumHeight, min(containerHeight - Self.reservedHeight, Self.maximumHeight))
  }

  static let minimumHeight: CGFloat = 120
  static let maximumHeight: CGFloat = 640
  /// Kept free below the card: the filters and search field, and about two results.
  static let reservedHeight: CGFloat = 300
  /// Below this the grid's hour labels and titles no longer fit, so it shows the silhouette.
  static let silhouetteHeight: CGFloat = 260
  /// Space around the card within the room screens leave for it.
  static let topSpacing: CGFloat = 4
  static let bottomSpacing: CGFloat = 12
}

extension EnvironmentValues {
  /// Set by the full-screen lecture search on its screens that show the preview; `nil` anywhere
  /// else, including its inspector, where the timetable is already beside it.
  @Entry var lectureSearchTimetablePreview: LectureSearchTimetablePreview? = nil
}

extension View {
  /// In the full-screen lecture search, adds the Timetable button and leaves room for the
  /// preview card. Does nothing elsewhere.
  func lectureSearchTimetablePreview() -> some View {
    modifier(LectureSearchTimetablePreviewModifier())
  }
}

private struct LectureSearchTimetablePreviewModifier: ViewModifier {
  @Environment(\.lectureSearchTimetablePreview) private var preview
  @State private var screenID = UUID()
  @State private var isOnScreen = false
  /// The preview this screen is counted in, to leave when the environment's changes.
  @State private var registeredPreview: LectureSearchTimetablePreview?

  // The modifiers apply whether or not there is a preview, so the screen keeps its identity, and
  // with it its state, when the preview comes or goes.
  func body(content: Content) -> some View {
    content
      // Room for the card, which floats over the search. A bar, so content scrolls under the
      // card with the scroll edge effect.
      .safeAreaBar(edge: .top, spacing: 0) {
        if let preview, preview.isExpanded, preview.containerHeight > 0 {
          Color.clear
            .frame(height: LectureSearchTimetablePreview.topSpacing + preview.restingHeight + LectureSearchTimetablePreview.bottomSpacing)
            .onGeometryChange(for: CGFloat.self) { $0.frame(in: .global).minY } action: { top in
              preview.cardTop = top
            }
        }
      }
      .scrollEdgeEffectStyle(.soft, for: [.top, .bottom])
      .onGeometryChange(for: CGFloat.self) { $0.size.height } action: { height in
        preview?.containerHeight = height
      }
      .onAppear {
        isOnScreen = true
        register()
      }
      .onDisappear {
        isOnScreen = false
        register()
      }
      .onChange(of: preview.map(ObjectIdentifier.init)) {
        register()
      }
      .toolbar {
        if let preview {
          ToolbarItem(placement: .topBarTrailing) {
            TimetablePreviewButton(preview: preview)
          }
        }
      }
  }

  /// Counts this screen in the preview it shows while on screen, so the card shows only over
  /// screens with room for it.
  private func register() {
    let current = isOnScreen ? preview : nil
    guard current !== registeredPreview else { return }
    withAnimation(.smooth(duration: 0.2)) {
      _ = registeredPreview?.screens.remove(screenID)
      _ = current?.screens.insert(screenID)
    }
    registeredPreview = current
  }
}

/// The preview card over the search's navigation stack, placed where its screens leave room.
struct LectureSearchPreviewOverlay: View {
  let preview: LectureSearchTimetablePreview

  var body: some View {
    GeometryReader { proxy in
      if preview.isShown {
        TimetablePreviewCard(preview: preview)
          .padding(.horizontal)
          .contentWidth()
          .padding(.top, max(0, preview.cardTop - proxy.frame(in: .global).minY) + LectureSearchTimetablePreview.topSpacing)
          .transition(.scale(scale: 0.9, anchor: .topTrailing).combined(with: .opacity))
      }
    }
  }
}

/// Shows or hides the preview. Filled while the preview is shown.
private struct TimetablePreviewButton: View {
  let preview: LectureSearchTimetablePreview

  var body: some View {
    let button = Button(String(localized: "Timetable", bundle: .module), systemImage: "calendar") {
      withAnimation(.smooth(duration: 0.3)) {
        preview.isExpanded.toggle()
      }
    }
    .accessibilityAddTraits(preview.isExpanded ? .isSelected : [])

    if preview.isExpanded {
      button.buttonStyle(.glassProminent)
    } else {
      button
    }
  }
}

/// The timetable being added to, with the lecture being looked at drawn in as a candidate.
/// A handle along its bottom edge resizes it; too short for the grid's text, it shows the
/// timetable's silhouette in the proportions of an Apple Watch screen instead.
private struct TimetablePreviewCard: View {
  let preview: LectureSearchTimetablePreview
  /// The card's height minus the drag's translation: where the drag is measured from. Moved
  /// when the drag passes a limit, so moving back takes effect at once.
  @State private var dragAnchor: CGFloat?
  /// Ends the drag when it is cancelled, which does not call `onEnded`.
  @GestureState private var isDragging = false
  /// Changes when a resize crosses between the grid and the silhouette.
  @State private var modeChanges = 0
  @Environment(\.timetableTheme) private var theme

  var body: some View {
    let height = preview.displayedHeight
    let showsSilhouette = height < LectureSearchTimetablePreview.silhouetteHeight
    let timetableViewModel = preview.timetableViewModel

    ThemedGridCard {
      Group {
        if showsSilhouette {
          TimetableSilhouetteView(
            timetable: timetableViewModel.timetableWithCandidate,
            // Faint, so the lectures stand out, and readable over a themed background too.
            trackColor: (theme.gridLabelColor ?? .primary).opacity(0.07),
            candidateLectureID: timetableViewModel.candidateLecture?.id
          )
          .padding(.bottom, Self.handleRoom)
          .transition(.opacity)
        } else {
          TimetableGrid(
            selectedTimetable: timetableViewModel.timetableWithCandidate,
            candidateLecture: timetableViewModel.candidateLecture,
            placement: .view
          )
          .transition(.opacity)
        }
      }
      // A preview only: lectures in it are opened from the results.
      .allowsHitTesting(false)
      .animation(.smooth(duration: 0.2), value: showsSilhouette)
    }
    // An opaque base, since the card floats over the results.
    .background(Color.secondarySystemGroupedBackground, in: .rect(cornerRadius: 28))
    .animation(.smooth(duration: 0.3)) { card in
      card.frame(width: showsSilhouette ? height * Self.watchAspectRatio : nil)
    }
    .frame(height: height)
    .overlay(alignment: .bottom) {
      resizeHandle
    }
    .shadow(color: .black.opacity(0.14), radius: 24, y: 10)
    // Under the Timetable button that shows it.
    .frame(maxWidth: .infinity, alignment: .trailing)
    // Only for resizing by hand, not for a screen or keyboard that changes the default height.
    .sensoryFeedback(.selection, trigger: modeChanges)
    .onChange(of: isDragging) { _, isDragging in
      if !isDragging {
        endDrag()
      }
    }
  }

  private var resizeHandle: some View {
    Capsule()
      .fill(.gray.opacity(0.6))
      .frame(width: 36, height: 5)
      .padding(.bottom, 6)
      // Taller than it looks, so it is easy to catch.
      .frame(maxWidth: .infinity, minHeight: 28, alignment: .bottom)
      .contentShape(.rect)
      .gesture(
        // From the first touch, and in global space, since the handle moves with the edge it
        // resizes.
        DragGesture(minimumDistance: 0, coordinateSpace: .global)
          .updating($isDragging) { _, isDragging, _ in
            isDragging = true
          }
          .onChanged { value in
            drag(by: value.translation.height)
          }
          .onEnded { _ in
            endDrag()
          }
      )
      .accessibilityElement()
      .accessibilityLabel(Text("Timetable Preview Height", bundle: .module))
      .accessibilityValue(Text(preview.displayedHeight < LectureSearchTimetablePreview.silhouetteHeight
        ? String(localized: "Compact", bundle: .module)
        : String(localized: "Detailed", bundle: .module)))
      .accessibilityAdjustableAction { direction in
        switch direction {
        case .increment: setHeight(preview.restingHeight + Self.accessibilityStep)
        case .decrement: setHeight(preview.restingHeight - Self.accessibilityStep)
        @unknown default: break
        }
      }
  }

  private func drag(by translation: CGFloat) {
    // Too short a screen to resize on, such as a phone in landscape: keep the size chosen on a
    // taller one rather than overwrite it with the minimum.
    guard preview.isResizable else { return }
    let anchor = dragAnchor ?? preview.displayedHeight - translation
    let height = preview.clamped(anchor + translation)
    dragAnchor = height - translation
    let wasSilhouette = preview.displayedHeight < LectureSearchTimetablePreview.silhouetteHeight
    preview.dragHeight = height
    if (height < LectureSearchTimetablePreview.silhouetteHeight) != wasSilhouette {
      modeChanges += 1
    }
  }

  /// Keeps the height the drag reached, and lets the screens catch up with it.
  private func endDrag() {
    dragAnchor = nil
    guard let dragHeight = preview.dragHeight else { return }
    withAnimation(.smooth(duration: 0.3)) {
      preview.height = dragHeight
      preview.dragHeight = nil
    }
  }

  private func setHeight(_ height: CGFloat) {
    guard preview.isResizable else { return }
    let wasSilhouette = preview.restingHeight < LectureSearchTimetablePreview.silhouetteHeight
    withAnimation(.smooth(duration: 0.3)) {
      preview.height = preview.clamped(height)
    }
    if (preview.restingHeight < LectureSearchTimetablePreview.silhouetteHeight) != wasSilhouette {
      modeChanges += 1
    }
  }

  /// Width to height of an Apple Watch screen, such as the 45mm's 396 by 484 pixels.
  private static let watchAspectRatio: CGFloat = 396 / 484
  /// Keeps the silhouette's blocks clear of the handle.
  private static let handleRoom: CGFloat = 8
  private static let accessibilityStep: CGFloat = 60
}
