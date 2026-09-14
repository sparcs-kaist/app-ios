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

  public var body: some View {
    GeometryReader { geometry in
      ZStack(alignment: .topLeading) {
        RoundedRectangle(cornerRadius: 4)
          .foregroundStyle(backgroundColor)
          .widgetAccentable()
          .opacity(renderingMode == .accented ? 0.2 : 1)
        
        VStack(alignment: .leading, spacing: placement == .widget ? 2 : 4) {
          Text(lectureItem.lecture.name)
            .minimumScaleFactor(placement == .widget ? 0.8 : 1)
            .font(.caption)
            .lineLimit(3)
          
          if geometry.size.height > 40 {
            Text("\(lectureItem.lectureClass.buildingCode) \(lectureItem.lectureClass.buildingName)", bundle: .module)
              .minimumScaleFactor(0.8)
              .lineLimit(2)
              .font(.caption2)
              .opacity(0.8)
          }
        }
        .foregroundStyle(isCandidate ? .white : lectureItem.lecture.textColor)
        .padding(6)
      }
      .frame(width: geometry.size.width, height: geometry.size.height, alignment: .topLeading)
      .clipped()
      .modifier(TimetableGlassModifier(
        placement: placement,
        colorScheme: colorScheme,
        cellColor: cellColor
      ))
    }
  }

  private var cellColor: Color {
    isCandidate ? Color.accentColor : lectureItem.lecture.backgroundColor
  }

  private var backgroundColor: Color {
    var color: Color = cellColor

    switch placement {
    case .widget:
      color = colorScheme == .light ? color : color.darkTransformedHSB()
    default:
      color = colorScheme == .light ? Color.clear : color.darkTransformedHSB()
    }

    return color
  }
}

struct TimetableGlassModifier: ViewModifier {
  let placement: TimetablePlacement
  let colorScheme: ColorScheme
  let cellColor: Color

  func body(content: Content) -> some View {
    if placement == .view && colorScheme == .light {
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
