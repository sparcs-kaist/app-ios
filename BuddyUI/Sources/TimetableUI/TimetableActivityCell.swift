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

  var body: some View {
    GeometryReader { geometry in
      ZStack(alignment: .topLeading) {
        RoundedRectangle(cornerRadius: 4)
          .fill(backgroundColor)
          .widgetAccentable()
          .opacity(renderingMode == .accented ? 0.2 : 1)
        // Packed as lecture cells are; see `TimetableGridCell`.
        let isPacked = placement != .widget && (geometry.size.width < 72 || geometry.size.height < 60)
        VStack(alignment: .leading, spacing: placement == .widget || isPacked ? 2 : 4) {
          Text(activity.title)
						.minimumScaleFactor(placement == .widget ? 0.8 : 1)
						.font(isPacked ? .caption2.weight(.medium) : .caption)
						.lineLimit(isPacked && geometry.size.height < 60 ? 2 : 3)
						.layoutPriority(1)
					
          if geometry.size.height > 40, !activity.location.isEmpty {
            Text(activity.location)
							.minimumScaleFactor(placement == .widget ? 0.8 : 1)
							.lineLimit(isPacked ? 1 : 2)
							.font(.caption2)
							.opacity(0.8)
          }
        }
        .padding(.horizontal, isPacked ? 3 : 6)
        .padding(.vertical, isPacked ? 4 : 6)
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
