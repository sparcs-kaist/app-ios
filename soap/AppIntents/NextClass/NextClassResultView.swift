//
//  NextClassResultView.swift
//  soap
//
//  Created by Soongyu Kwon on 09/10/2025.
//

import SwiftUI
import BuddyDomain

struct NextClassResultView: View {
  enum ViewState {
    case success(item: LectureItem?)
    case error
  }
  let state: ViewState

  var body: some View {
    Group {
      switch state {
      case .success(let item):
        if let item {
          // success
          let classtime: ClassTime = item.lecture.classTimes[item.index]
          contentView(
            title: item.lecture.title.localized(),
            subtitle: classtime.classroomNameShort.localized(),
            date: dateOnSameDay(minutes: classtime.begin, date: Date(), calendar: .current) ?? Date(),
            color: item.lecture.backgroundColor
          )
        } else {
          // no mor classes
          contentView(
            title: "No more classes today",
            subtitle: "Enjoy your day.",
            date: nil,
            color: .accent
          )
        }
      case .error:
        Text("Failed to load classes for this semester.")
      }
    }
    .padding()
  }

  func contentView(title: String, subtitle: String, date: Date?, color: Color) -> some View {
    VStack(alignment: .leading) {
      HStack(alignment: .top) {
        Text(title)
          .fontWeight(.semibold)
          .lineLimit(2)

        Spacer()

        if let date {
          Text(
            date,
            format: .relative(presentation: .named)
          )
          .foregroundStyle(color)
          .font(.caption)
          .fontWeight(.medium)
          .fontDesign(.rounded)
        }
      }

      Group {
        if let date {
          Text("\(date, style: .time) at \(subtitle)")
        } else {
          Text(subtitle)
        }
      }
      .foregroundStyle(.secondary)
      .font(.caption)
    }
  }
}
