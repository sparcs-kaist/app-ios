//
//  TimetableGridCell.swift
//  soap
//
//  Created by Soongyu Kwon on 28/12/2024.
//

import SwiftUI
import WidgetKit
import BuddyDomain

public struct TimetableGridCell: View {
  let lectureItem: LectureItem
  let isCandidate: Bool
  let onDeletion: (() -> Void)?
  let placement: TimetablePlacement

  public init(
    lectureItem: LectureItem,
    isCandidate: Bool,
    onDeletion: (() -> Void)?,
    placement: TimetablePlacement
  ) {
    self.lectureItem = lectureItem
    self.isCandidate = isCandidate
    self.onDeletion = onDeletion
    self.placement = placement
  }

  @Environment(\.widgetRenderingMode) var renderingMode
  @Environment(\.colorScheme) private var colorScheme

  public var body: some View {
    GeometryReader { geometry in
      ZStack(alignment: .topLeading) {
        RoundedRectangle(cornerRadius: 4) // this feels unnecessary but removing it breaks the whole view
          .foregroundStyle(backgroundColor)
          .widgetAccentable()
          .opacity(renderingMode == .accented ? 0.2 : 1)

        VStack(alignment: .leading, spacing: placement == .widget ? 2 : 4) {
          Text(lectureItem.lecture.name)
            .minimumScaleFactor(placement == .widget ? 0.8 : 1)
            .font(.caption)
            .lineLimit(3)

          if geometry.size.height > 40 {
            Text("\(lectureItem.lectureClass.buildingCode) \(lectureItem.lectureClass.buildingName)")
              .minimumScaleFactor(0.8)
              .lineLimit(2)
              .font(.caption2)
              .opacity(0.8)
          }
        }
        .foregroundStyle(isCandidate ? .white : lectureItem.lecture.textColor)
        .padding(6)
      }
      .modifier(TimetableGlassModifier(
        placement: placement,
        colorScheme: colorScheme,
        cellColor: cellColor
      ))
      .modifier(TimetableContextMenuModifier(placement: placement, onDeletion: onDeletion))
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

private struct TimetableContextMenuModifier: ViewModifier {
  let placement: TimetablePlacement
  let onDeletion: (() -> Void)?

  func body(content: Content) -> some View {
    if placement == .widget {
      content
    } else {
      content
        .contextMenu {
          Button("Remove from Table", systemImage: "trash", role: .destructive) {
            onDeletion?()
          }
        }
    }
  }
}

private struct TimetableGlassModifier: ViewModifier {
  let placement: TimetablePlacement
  let colorScheme: ColorScheme
  let cellColor: Color

  func body(content: Content) -> some View {
    if placement == .view {
      content
        .glassEffect(
          colorScheme == .light ? .regular
            .tint(cellColor)
          : .identity,
          in: .rect(cornerRadius: 4)
        )
    } else {
      content
    }
  }
}

//#Preview(traits: .fixedLayout(width: 88, height: 105)) {
//  TimetableGridCell(lecture: Lecture.mockList[0], isCandidate: false, onDeletion: nil)
//}
//
//#Preview(traits: .fixedLayout(width: 88, height: 105)) {
//  TimetableGridCell(lecture: Lecture.mockList[1], isCandidate: false, onDeletion: nil)
//}
//
//#Preview(traits: .fixedLayout(width: 88, height: 105)) {
//  TimetableGridCell(lecture: Lecture.mockList[2], isCandidate: false, onDeletion: nil)
//}
//
//#Preview(traits: .fixedLayout(width: 88, height: 105)) {
//  TimetableGridCell(lecture: Lecture.mockList[3], isCandidate: false, onDeletion: nil)
//}

