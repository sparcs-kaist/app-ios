//
//  TimetableGrid.swift
//  soap
//
//  Created by Soongyu Kwon on 11/09/2026.
//

import SwiftUI
import WidgetKit
import BuddyDomain
#if os(iOS)
import UIKit
#endif

struct TimetableActivityCell: View {
  let slot: TimetableActivitySlot
  let placement: TimetablePlacement
  private var activity: TimetableActivity { slot.activity }
  @Environment(\.colorScheme) private var colorScheme
  @Environment(\.widgetRenderingMode) private var renderingMode
  @Environment(\.timetableTheme) private var theme
  @ScaledMetric(relativeTo: .caption) private var captionLineHeight: CGFloat = 16
  @ScaledMetric(relativeTo: .caption2) private var caption2LineHeight: CGFloat = 13

  var body: some View {
    GeometryReader { geometry in
      ZStack(alignment: .topLeading) {
        RoundedRectangle(cornerRadius: 4)
          .fill(backgroundColor)
          .widgetAccentable()
          .opacity(renderingMode == .accented ? 0.2 : 1)
        // Packed as lecture cells are; see `TimetableGridCell`.
        let isPacked = geometry.size.width < 72 || geometry.size.height < 60
        let spacing: CGFloat = placement == .widget || isPacked ? 2 : 4
        let verticalPadding: CGFloat = isPacked ? 4 : 6
        let lines = TimetableCellLines(
          height: geometry.size.height - verticalPadding * 2,
          titleLineHeight: isPacked ? caption2LineHeight : captionLineHeight,
          detailLineHeight: caption2LineHeight,
          spacing: spacing,
          maxRoomLines: isPacked ? 1 : 2,
          maxSubtitleLines: 0
        )
        VStack(alignment: .leading, spacing: lines.spacing) {
          Text(activity.title)
						.minimumScaleFactor(placement == .widget && !isPacked ? 0.8 : 1)
						.font(isPacked ? .caption2.weight(.medium) : .caption)
						.lineLimit(isPacked && geometry.size.height < 60 ? 2 : 3)
					
          if lines.room > 0, !activity.location.isEmpty {
            Text(activity.location)
							.minimumScaleFactor(placement == .widget && !isPacked ? 0.8 : 1)
							.lineLimit(lines.room)
							.font(.caption2)
							.opacity(0.8)
							.layoutPriority(2)
          }
        }
        .padding(.horizontal, isPacked ? 3 : 6)
        .padding(.vertical, verticalPadding)
        .foregroundStyle(theme.textColor)
      }
      .frame(width: geometry.size.width, height: geometry.size.height, alignment: .topLeading)
      .clipped()
      .modifier(TimetableGlassModifier(placement: placement, colorScheme: colorScheme, cellColor: cellColor))
    }
    .contentShape(.rect)
    .accessibilityElement(children: .ignore)
    .accessibilityLabel(Text("\(activity.title), \(activity.location), \(TimetableTimeSelection.formattedTime(slot.begin)) – \(TimetableTimeSelection.formattedTime(slot.end))"))
    .accessibilityIdentifier(slot.timeIndex == 0 ? "activity.cell.\(activity.id)" : "activity.cell.\(activity.id).\(slot.timeIndex)")
    .modifier(ActivityPopoverModifier(activity: activity, isEnabled: placement == .view))
  }

  private var cellColor: Color {
    theme.color(forActivityID: activity.id)
  }

  private var backgroundColor: Color {
    if colorScheme == .dark { return cellColor.darkTransformedHSB() }
    return placement == .view ? .clear : cellColor
  }
}

private struct ActivityPopoverModifier: ViewModifier {
  let activity: TimetableActivity
  let isEnabled: Bool
  @State private var isPresented = false

  @ViewBuilder
  func body(content: Content) -> some View {
    // Popover presentations don't exist on watchOS, and the watch never uses
    // the interactive .view placement this modifier is enabled for.
    #if os(watchOS)
    content
    #else
    if isEnabled {
      content
        .onTapGesture {
					isPresented = true
					#if os(iOS)
					UISelectionFeedbackGenerator().selectionChanged()
					#endif
				}
        .accessibilityAddTraits(.isButton)
        .popover(isPresented: $isPresented) {
          VStack(alignment: .leading, spacing: 8) {
            Text(activity.title)
              .font(.headline)
            if !activity.location.isEmpty {
              Label(activity.location, systemImage: "mappin.and.ellipse")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            }
          }
          .frame(idealWidth: 240, maxWidth: 280, alignment: .leading)
          .fixedSize(horizontal: false, vertical: true)
          .padding()
          .accessibilityIdentifier("activity.details")
          .presentationCompactAdaptation(.popover)
        }
    } else {
      content
    }
    #endif
  }
}
