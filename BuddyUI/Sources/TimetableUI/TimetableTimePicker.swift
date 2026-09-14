import SwiftUI
import UIKit
import BuddyDomain

/// An editable overlay on the shared timetable. The binding is a local creation draft.
public struct TimetableTimePicker: View {
  let timetable: Timetable?
  let title: String
  let occupiedTimes: [TimetableTimeSelection]
  @Binding var selection: TimetableTimeSelection

  @State private var days: [DayType]
  @State private var scrollPosition = ScrollPosition()
  @State private var scrollOffset: CGFloat = 0
  @State private var interaction: Interaction?
  @GestureState private var gestureActive = false
  @State private var didScrollToSelection = false

  private let pointsPerMinute: CGFloat = 1.2
  private let contentPadding: CGFloat = 16
  private let coordinateSpace = "activity-timetable-viewport"
  private let dropAnimation = Animation.spring(response: 0.3, dampingFraction: 0.8)

  public init(
    timetable: Timetable?,
    title: String,
    selection: Binding<TimetableTimeSelection>,
    occupiedTimes: [TimetableTimeSelection] = []
  ) {
    self.timetable = timetable
    self.title = title
    self._selection = selection
    self.occupiedTimes = occupiedTimes
    // Keep the columns stable for the whole editing session, including during a drag.
    self._days = State(initialValue: selection.wrappedValue.editingDays)
  }

  private var isMoving: Bool { interaction?.kind == .move }

  private var hasConflict: Bool {
    !selection.conflictingLectures(in: timetable).isEmpty || !selection.conflictingActivities(in: timetable).isEmpty || occupiedTimes.contains(where: selection.overlaps)
  }

  public var body: some View {
    GeometryReader { viewport in
      let layout = TimetableLayout(
        classes: timetable?.lectures.flatMap(\.classes) ?? [],
        activities: timetable?.activities ?? [],
        placement: .view, beginTime: 0, endTime: 24 * 60
      )
      let gridHeight = TimetableLayout.contentTop + CGFloat(layout.endMinutes - layout.startMinutes) * pointsPerMinute
      let contentWidth = max(0, viewport.size.width - contentPadding * 2)
      let dayWidth = max(0, (contentWidth - TimetableLayout.contentLeading - TimetableLayout.cellSpacing * CGFloat(days.count - 1)) / CGFloat(days.count))
      let dayStride = dayWidth + TimetableLayout.cellSpacing

      ScrollView(.vertical) {
        TimetableGrid(
          selectedTimetable: timetable,
          visibleDays: days,
          showsDayHeader: false,
          beginTime: 0,
          endTime: 24 * 60,
          placement: .view
        )
        .allowsHitTesting(false)
        .frame(width: contentWidth, height: gridHeight)
        .padding(.horizontal, contentPadding)
      }
      .scrollPosition($scrollPosition, anchor: .topLeading)
      .scrollDisabled(interaction != nil)
      .onScrollGeometryChange(for: CGFloat.self) { geometry in
        // The scroll view extends under navigation chrome; the floating block
        // is positioned in the safe-area viewport, so normalize its scroll origin.
        geometry.contentOffset.y + geometry.contentInsets.top
      } action: { _, offset in
        scrollOffset = offset
        updateSelection(dayStride: dayStride)
      }
      .overlay(alignment: .topLeading) {
        // Day labels remain visible as the user scrolls through the day.
        HStack(spacing: TimetableLayout.cellSpacing) {
          ForEach(days) { day in
            Text(day.stringValue)
              .font(.caption.weight(.semibold))
              .textCase(.uppercase)
              .foregroundStyle(day == selection.day ? Color.indigo : .secondary)
              .frame(width: dayWidth, height: TimetableLayout.contentTop)
          }
        }
        .padding(.leading, TimetableLayout.contentLeading)
        .padding(.horizontal, contentPadding)
        .frame(width: viewport.size.width, alignment: .leading)
        .background(.regularMaterial, ignoresSafeAreaEdges: [])
        .allowsHitTesting(false)
      }
      .overlay(alignment: .topLeading) {
        // This overlay stays in viewport coordinates. A lifted block follows the
        // finger continuously, independently of its snapped time/day preview.
        indicator(dayWidth: dayWidth, dayStride: dayStride)
          .offset(indicatorOffset(layout: layout, gridHeight: gridHeight, dayStride: dayStride))
          .frame(width: viewport.size.width, height: viewport.size.height, alignment: .topLeading)
          .clipShape(IndicatorClip(isLifted: isMoving, bottomInset: viewport.safeAreaInsets.bottom))
      }
      .onScrollGeometryChange(for: CGSize.self) { geometry in
        geometry.contentSize
      } action: { _, size in
        guard !didScrollToSelection, size.height > 0 else { return }
        didScrollToSelection = true
        scrollPosition.scrollTo(y: max(0, CGFloat(selection.begin) * pointsPerMinute - 90))
      }
      .task(id: interaction != nil) {
        guard interaction != nil else { return }
        while !Task.isCancelled && interaction != nil {
          do { try await Task.sleep(for: .milliseconds(50)) } catch { return }
          autoScroll(viewport: viewport.size, gridHeight: gridHeight)
        }
      }
      .onChange(of: gestureActive) { _, active in
        // Gesture cancellation returns the draft to where it was picked up.
        if !active, interaction != nil { finishInteraction(cancelled: true) }
      }
      .onChange(of: selection) { _, _ in
        if interaction?.kind != .move, interaction != nil {
          UISelectionFeedbackGenerator().selectionChanged()
        }
      }
      .onChange(of: hasConflict) { _, conflict in
        if conflict { UINotificationFeedbackGenerator().notificationOccurred(.warning) }
      }
    }
    .coordinateSpace(name: coordinateSpace)
  }

  private func indicatorOffset(layout: TimetableLayout, gridHeight: CGFloat, dayStride: CGFloat) -> CGSize {
    if let interaction, interaction.kind == .move {
      return CGSize(
        width: contentPadding + TimetableLayout.contentLeading + CGFloat(days.firstIndex(of: interaction.origin.day) ?? 0) * dayStride + interaction.translation.width,
        height: layout.offset(at: interaction.origin.begin, height: gridHeight) - interaction.initialOffset + interaction.translation.height
      )
    }
    return CGSize(
      width: contentPadding + TimetableLayout.contentLeading + CGFloat(days.firstIndex(of: selection.day) ?? 0) * dayStride,
      height: layout.offset(at: selection.begin, height: gridHeight) - scrollOffset
    )
  }

  private func indicator(dayWidth: CGFloat, dayStride: CGFloat) -> some View {
    let height = CGFloat(selection.duration) * pointsPerMinute - TimetableLayout.cellSpacing

    return ZStack(alignment: .topLeading) {
      RoundedRectangle(cornerRadius: 4)
        .fill(.indigo.opacity(isMoving ? 0.32 : 0.22))
      RoundedRectangle(cornerRadius: 4)
        .strokeBorder(hasConflict ? Color.red : .indigo, style: StrokeStyle(lineWidth: 2, dash: hasConflict ? [4, 3] : []))
      VStack(alignment: .leading, spacing: 3) {
        Text(title.isEmpty ? String(localized: "New Activity", bundle: .module) : title)
          .font(.caption.weight(.semibold))
          .lineLimit(2)
        if height > 55 {
          Text(selection.formattedTimeRange)
            .font(.caption2)
            .lineLimit(2)
						.contentTransition(.numericText())
						.animation(.spring, value: selection.formattedTimeRange)
        }
      }
      .foregroundStyle(.indigo)
      .padding(6)
      .frame(width: dayWidth, height: height, alignment: .topLeading)
      .clipped()
    }
    .frame(width: dayWidth, height: height)
    .contentShape(.rect)
    .gesture(moveGesture(dayStride: dayStride))
    .accessibilityElement(children: .ignore)
    .accessibilityIdentifier("activity.timeBlock")
    .accessibilityLabel(Text(title.isEmpty ? String(localized: "New Activity", bundle: .module) : title))
    .accessibilityValue(Text("\(selection.day.stringValue), \(selection.formattedTimeRange)"))
    .accessibilityHint(Text("Long press to move. Drag the handles to change the start or end time.", bundle: .module))
    .accessibilityAdjustableAction { direction in
      let delta = direction == .increment ? TimetableTimeSelection.minuteStep : -TimetableTimeSelection.minuteStep
      selection = selection.moving(to: selection.begin + delta, on: selection.day)
      scrollPosition.scrollTo(y: max(0, CGFloat(selection.begin) * pointsPerMinute - 90))
    }
    .accessibilityAction(named: Text("Previous day", bundle: .module)) { moveDay(by: -1) }
    .accessibilityAction(named: Text("Next day", bundle: .module)) { moveDay(by: 1) }
    .overlay(alignment: .topTrailing) {
      handle(.start, dayStride: dayStride).offset(x: 12, y: -16)
    }
    .overlay(alignment: .bottomLeading) {
      handle(.end, dayStride: dayStride).offset(x: -12, y: 16)
    }
    .scaleEffect(isMoving ? 1.06 : 1)
    .shadow(color: .indigo.opacity(isMoving ? 0.25 : 0), radius: isMoving ? 12 : 0, y: isMoving ? 6 : 0)
    .animation(dropAnimation, value: isMoving)
  }

  private func handle(_ kind: Interaction.Kind, dayStride: CGFloat) -> some View {
    Circle()
      .fill(.indigo)
      .frame(width: 11, height: 11)
      .overlay { Circle().stroke(.background, lineWidth: 2) }
      .frame(width: 44, height: 32)
      .contentShape(.rect)
      .highPriorityGesture(resizeGesture(kind, dayStride: dayStride))
      .accessibilityElement()
      .accessibilityIdentifier(kind == .start ? "activity.startHandle" : "activity.endHandle")
      .accessibilityLabel(Text(kind == .start ? String(localized: "Start time", bundle: .module) : String(localized: "End time", bundle: .module)))
      .accessibilityValue(Text(TimetableTimeSelection.formattedTime(kind == .start ? selection.begin : selection.end)))
      .accessibilityAdjustableAction { direction in
        let delta = direction == .increment ? TimetableTimeSelection.minuteStep : -TimetableTimeSelection.minuteStep
        selection = kind == .start
          ? selection.resizingStart(to: selection.begin + delta)
          : selection.resizingEnd(to: selection.end + delta)
      }
  }

  private func moveGesture(dayStride: CGFloat) -> some Gesture {
    LongPressGesture(minimumDuration: 0.35, maximumDistance: 12)
      .sequenced(before: DragGesture(minimumDistance: 0, coordinateSpace: .named(coordinateSpace)))
      .updating($gestureActive) { value, active, _ in
        if case .second(true, _) = value { active = true }
      }
      .onChanged { value in
        if case .second(true, let drag) = value {
          beginInteraction(.move)
          if let drag { updateInteraction(drag, dayStride: dayStride) }
        }
      }
      .onEnded { value in
        if case .second(true, let drag) = value, let drag {
          updateInteraction(drag, dayStride: dayStride)
        }
        finishInteraction()
      }
  }

  private func resizeGesture(_ kind: Interaction.Kind, dayStride: CGFloat) -> some Gesture {
    DragGesture(minimumDistance: 0, coordinateSpace: .named(coordinateSpace))
      .updating($gestureActive) { _, active, _ in active = true }
      .onChanged { drag in
        beginInteraction(kind)
        updateInteraction(drag, dayStride: dayStride)
      }
      .onEnded { drag in
        updateInteraction(drag, dayStride: dayStride)
        finishInteraction()
      }
  }

  private func beginInteraction(_ kind: Interaction.Kind) {
    guard interaction == nil else { return }
    interaction = Interaction(kind: kind, origin: selection, initialOffset: scrollOffset)
    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
  }

  private func finishInteraction(cancelled: Bool = false) {
    guard let interaction else { return }
    withAnimation(dropAnimation) {
      if cancelled { selection = interaction.origin }
      self.interaction = nil
    }
    if !cancelled { UIImpactFeedbackGenerator(style: .light).impactOccurred() }
  }

  private func updateInteraction(_ drag: DragGesture.Value, dayStride: CGFloat) {
    interaction?.translation = drag.translation
    interaction?.location = drag.location
    updateSelection(dayStride: dayStride)
  }

  private func updateSelection(dayStride: CGFloat) {
    guard let interaction else { return }
    let minutes = Int((interaction.translation.height + scrollOffset - interaction.initialOffset) / pointsPerMinute)
    switch interaction.kind {
    case .move:
      let shift = Int((interaction.translation.width / dayStride).rounded())
      let dayIndex = min(max((days.firstIndex(of: interaction.origin.day) ?? 0) + shift, 0), days.count - 1)
      selection = interaction.origin.moving(to: interaction.origin.begin + minutes, on: days[dayIndex])
    case .start:
      selection = interaction.origin.resizingStart(to: interaction.origin.begin + minutes)
    case .end:
      selection = interaction.origin.resizingEnd(to: interaction.origin.end + minutes)
    }
  }

  private func autoScroll(viewport: CGSize, gridHeight: CGFloat) {
    guard let location = interaction?.location else { return }
    let step: CGFloat
    if location.y < 60 {
      step = -min(12, (60 - location.y) / 3)
    } else if location.y > viewport.height - 44 {
      step = min(12, (location.y - viewport.height + 44) / 3)
    } else {
      return
    }
    let y = min(max(scrollOffset + step, 0), max(0, gridHeight - viewport.height))
    scrollPosition.scrollTo(y: y)
  }

  private func moveDay(by delta: Int) {
    let index = min(max((days.firstIndex(of: selection.day) ?? 0) + delta, 0), days.count - 1)
    selection = selection.moving(to: selection.begin, on: days[index])
  }

  private struct Interaction {
    enum Kind { case move, start, end }
    let kind: Kind
    let origin: TimetableTimeSelection
    let initialOffset: CGFloat
    var translation: CGSize = .zero
    var location: CGPoint?
  }

  private struct IndicatorClip: Shape {
    let isLifted: Bool
    let bottomInset: CGFloat

    func path(in rect: CGRect) -> Path {
      // Match the scroll content's extension through the bottom safe area while
      // keeping a resting block beneath the pinned header.
      let visible = isLifted
        ? rect.insetBy(dx: -rect.width, dy: -rect.height)
        : CGRect(x: rect.minX, y: TimetableLayout.contentTop, width: rect.width, height: max(0, rect.height + bottomInset - TimetableLayout.contentTop))
      return Path(visible)
    }
  }
}
