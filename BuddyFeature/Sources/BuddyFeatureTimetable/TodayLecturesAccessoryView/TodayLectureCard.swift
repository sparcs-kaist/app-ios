//
//  TodayLectureCard.swift
//  BuddyFeature
//
//  Created by Soongyu Kwon on 09/03/2026.
//

import Foundation
import SwiftUI
import BuddyDomain

struct TodayLectureCard: View {
  let context: TimelineViewDefaultContext
  let item: LectureItem

  var body: some View {
    HStack {
      Circle()
        .fill(item.lecture.backgroundColor)
        .frame(width: 12, height: 12)
        .animation(.spring, value: context.date)

      VStack(alignment: .leading) {
        Text(item.lecture.name)
          .font(.headline)
          .lineLimit(1)
          .animation(.spring, value: context.date)
          .contentTransition(.numericText())

        Text("\(item.lectureClass.buildingCode) \(item.lectureClass.roomName)", bundle: .module)
          .font(.footnote)
          .foregroundStyle(.secondary)
          .animation(.spring, value: context.date)
          .contentTransition(.numericText())
      }

      Spacer()

      let time = dateForMinutes(item.lectureClass.begin, on: Date())
      Text(
        time,
        formatter: formatter(from: time)
      )
      .fontDesign(.rounded)
      .font(.callout)
      .animation(.spring, value: context.date)
      .contentTransition(.numericText())
    }
  }

  private func dateForMinutes(_ minutes: Int, on date: Date) -> Date {
    let calendar = Calendar.current
    let startOfDay = calendar.startOfDay(for: date)
    return calendar.date(byAdding: .minute, value: minutes, to: startOfDay) ?? date
  }

  private func formatter(from: Date) -> RelativeDateTimeFormatter {
    let formatter = RelativeDateTimeFormatter()
    formatter.unitsStyle = .short
    formatter.localizedString(for: from, relativeTo: Date())

    return formatter
  }
}
