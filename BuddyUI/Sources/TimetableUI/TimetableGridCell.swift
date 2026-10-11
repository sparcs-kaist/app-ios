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
        
        VStack(alignment: .leading, spacing: placement == .widget ? 2 : 4) {
          Text(lectureItem.lecture.name)
            .minimumScaleFactor(placement == .widget ? 0.8 : 1)
            .font(.caption)
            .lineLimit(3)
          
          if geometry.size.height > 40 {
            descriptionText
              .minimumScaleFactor(0.8)
              .lineLimit(2)
              .font(.caption2)
              .opacity(0.8)
          }
        }
        // Over the tint, the grid's own label colour reads like the hour labels beside it.
        .foregroundStyle(isCandidate ? theme.gridLabelColor ?? .primary : theme.textColor)
        .padding(6)
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

  private var descriptionText: Text {
    // Rendered exports prefer the professor, but lectures without one (like the
    // theme-sharing sample) fall back to the location instead of a blank line.
    if placement == .render, let professor = lectureItem.lecture.professors.first?.name, !professor.isEmpty {
      Text(professor)
    } else {
      Text("\(lectureItem.lectureClass.buildingCode) \(lectureItem.lectureClass.roomName)", bundle: .module)
    }
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
