//
//  UpcomingClassSmallWidgetView.swift
//  BuddyUI
//
//  Created by Soongyu Kwon on 26/12/2025.
//

import Foundation
import SwiftUI

public struct UpcomingClassSmallWidgetView: View {
  var entry: LectureEntry

  public init(entry: LectureEntry) {
    self.entry = entry
  }

  public var body: some View {
    if let lecture = entry.lecture, let ct = entry.lectureClass {
      VStack(alignment: .leading) {
        Text("Up Next", bundle: .module)
          .font(.caption)
          .fontWeight(.medium)
          .foregroundStyle(entry.backgroundColor)
          .textCase(.uppercase)

        Text(lecture.name)
          .lineLimit(2)
          .truncationMode(.tail)
          .fontWeight(.medium)

        Color.clear
          .frame(height: 1)

        Spacer()

        Text(ct.description)
          .fontWeight(.medium)
          .fontDesign(.rounded)
          .foregroundStyle(entry.backgroundColor)

        Text("\(ct.buildingCode) \(ct.roomName)", bundle: .module)
          .lineLimit(1)
          .minimumScaleFactor(0.8)
          .foregroundStyle(.secondary)
          .font(.callout)
      }
    } else if entry.signInRequired {
      Text("Sign in to see upcoming classes.", bundle: .module)
        .multilineTextAlignment(.center)
    } else {
      VStack(alignment: .leading) {
        Text(Date.now.formatted(.dateTime.weekday(.wide)))
          .font(.caption)
          .fontWeight(.medium)
          .foregroundStyle(.indigo)
          .textCase(.uppercase)

        Text(Date.now.formatted(.dateTime.day()))
          .font(.largeTitle)
          .fontWeight(.medium)

        Color.clear
          .frame(height: 1)

        Spacer()

        Text("No more classes", bundle: .module)
          .fontWeight(.medium)
          .fontDesign(.rounded)
          .foregroundStyle(.indigo)

        Text("Enjoy your day", bundle: .module)
          .lineLimit(1)
          .minimumScaleFactor(0.8)
          .foregroundStyle(.secondary)
          .font(.callout)
      }
    }
  }
}
