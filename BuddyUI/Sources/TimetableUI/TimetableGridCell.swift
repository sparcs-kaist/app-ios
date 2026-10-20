//
//  TimetableGridCell.swift
//  soap
//
//  Created by Soongyu Kwon on 28/12/2024.
//

import Foundation
import SwiftUI
import WidgetKit
import BuddyDomain

public struct TimetableGridCell: View {
  let lectureItem: LectureItem
  let isCandidate: Bool
  let placement: TimetablePlacement

  public init(
    lectureItem: LectureItem,
    isCandidate: Bool,
    placement: TimetablePlacement
  ) {
    self.lectureItem = lectureItem
    self.isCandidate = isCandidate
    self.placement = placement
  }

  @Environment(\.widgetRenderingMode) var renderingMode
  @Environment(\.colorScheme) private var colorScheme
  @Environment(\.timetableTheme) private var theme

  public var body: some View {
    GeometryReader { geometry in
      ZStack(alignment: .topLeading) {
        if isCandidate {
          // Only being previewed: the colour it would have, marked as not added yet.
          TentativeBlock(color: colorScheme == .light ? cellColor : cellColor.darkTransformedHSB())
        } else {
          RoundedRectangle(cornerRadius: 4)
            .foregroundStyle(backgroundColor)
            .widgetAccentable()
            .opacity(renderingMode == .accented ? 0.2 : 1)
        }
        
        let isPacked = isPackedCell(geometry.size)
        VStack(alignment: .leading, spacing: placement == .widget || isPacked ? 2 : 4) {
          Text(lectureItem.lecture.name)
            // Only widgets shrink their text to fit. Elsewhere every cell keeps one size, so a
            // grid doesn't mix sizes cell by cell; a long name ends in an ellipsis instead.
            .minimumScaleFactor(placement == .widget ? 0.8 : 1)
            // Packed, a size down and set apart from the room by weight instead.
            .font(isPacked ? .caption2.weight(.medium) : .caption)
            .lineLimit(isPacked && geometry.size.height < 60 ? 2 : 3)
            .layoutPriority(1)
          
          if geometry.size.height > 40 {
            // Ahead of the room: it tells apart sections of one course, such as
            // the Leadership ones, which the room and professor don't.
            if let subtitle = lectureItem.lecture.subtitleTopic {
              // Not scaled down to fit, so it matches the room beneath it. One line
              // in a short cell, so the room still shows.
              Text(subtitle)
                .lineLimit(geometry.size.height > 90 ? 3 : 1)
                .font(.caption2)
            }

            descriptionText(isPacked: isPacked)
              .minimumScaleFactor(placement == .widget ? 0.8 : 1)
              .lineLimit(isPacked ? 1 : 2)
              .font(.caption2)
              // Set a touch tighter in every packed cell, with the narrower sides, so a wide room
              // such as "W1-2 1201" fits.
              .tracking(isPacked ? -0.3 : 0)
              .opacity(0.8)
          }
        }
        // Over the tint, the grid's own label colour reads like the hour labels beside it.
        .foregroundStyle(isCandidate ? theme.gridLabelColor ?? .primary : theme.textColor)
        // Packed, narrower at the sides, for the room beneath the title.
        .padding(.horizontal, isPacked ? 3 : 6)
        .padding(.vertical, isPacked ? 4 : 6)
      }
      .frame(width: geometry.size.width, height: geometry.size.height, alignment: .topLeading)
      .clipped()
      .modifier(TimetableGlassModifier(
        placement: placement,
        colorScheme: colorScheme,
        cellColor: cellColor,
        isEnabled: !isCandidate
      ))
    }
  }

  private var cellColor: Color {
    theme.color(forCourseID: lectureItem.lecture.courseID)
  }

  /// Too small for the usual padding and room name, such as in a full week or the lecture search's
  /// timetable preview. Widgets size their text their own way.
  private func isPackedCell(_ size: CGSize) -> Bool {
    placement != .widget && (size.width < 72 || size.height < 60)
  }

  private func descriptionText(isPacked: Bool) -> Text {
    // Rendered exports prefer the professor, but lectures without one (like the
    // theme-sharing sample) fall back to the location instead of a blank line.
    if placement == .render, let professor = lectureItem.lecture.professors.first?.name, !professor.isEmpty {
      return Text(professor)
    }
    let room = lectureItem.lectureClass.roomName
    return Text("\(lectureItem.lectureClass.buildingCode) \(isPacked ? Self.roomNumber(in: room) ?? room : room)", bundle: .module)
  }

  /// The number from a room name such as "(1501호)강의실-제1공동강의실", all a packed cell has
  /// room for beside the building code; `nil` when the name has none.
  static func roomNumber(in roomName: String) -> String? {
    guard let match = roomName.firstMatch(of: /^\s*\(\s*([^)]+?)\s*호\s*\)/) else { return nil }
    return String(match.1)
  }

  private var backgroundColor: Color {
    var color: Color = cellColor

    switch placement {
    case .widget, .render:
      color = colorScheme == .light ? color : color.darkTransformedHSB()
    case .view:
      color = colorScheme == .light ? Color.clear : color.darkTransformedHSB()
    }

    return color
  }
}

struct TimetableGlassModifier: ViewModifier {
  let placement: TimetablePlacement
  let colorScheme: ColorScheme
  let cellColor: Color
  var isEnabled = true

  func body(content: Content) -> some View {
    if isEnabled && placement == .view && colorScheme == .light {
      content
        .glassEffect(.regular.tint(cellColor), in: .rect(cornerRadius: 4))
    } else {
      content
    }
  }
}

#Preview("App cell", traits: .fixedLayout(width: 88, height: 105)) {
  TimetableGridCell(lectureItem: .mock, isCandidate: false, placement: .view)
}

#Preview("Candidate", traits: .fixedLayout(width: 88, height: 105)) {
  TimetableGridCell(lectureItem: .mock, isCandidate: true, placement: .view)
}

#Preview("Widget cell", traits: .fixedLayout(width: 60, height: 55)) {
  TimetableGridCell(lectureItem: .mock, isCandidate: false, placement: .widget)
}

#Preview("Rendered cell", traits: .fixedLayout(width: 88, height: 105)) {
  TimetableGridCell(lectureItem: .mock, isCandidate: false, placement: .render)
}
