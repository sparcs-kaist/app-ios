//
//  UpcomingClassRectangleWidgetView.swift
//  soap
//
//  Created by Soongyu Kwon on 07/10/2025.
//

import SwiftUI
import WidgetKit
import BuddyDomain

public struct UpcomingClassRectangleWidgetView: View {
  @Environment(\.widgetRenderingMode) var renderingMode

  var entry: LectureEntry

  public init(entry: LectureEntry) {
    self.entry = entry
  }

  private var accentColor: Color {
    renderingMode == .fullColor ? entry.backgroundColor : .primary
  }

  public var body: some View {
    if let lecture = entry.lecture, let ct = entry.lectureClass {
      VStack(alignment: .leading, spacing: 2) {
        HStack(alignment: .center) {
          Circle()
            .frame(width: 12, height: 12)

          Text(ct.description)
            .fontDesign(.rounded)
            .lineLimit(1)
            .fontWeight(.semibold)
        }
        .foregroundStyle(accentColor)
        .widgetAccentable()

        Group {
          Text(lecture.name)
            .fontWeight(.semibold)
          HStack {
            Text("\(ct.buildingCode) \(ct.roomName)")
              .foregroundStyle(.secondary)
            Spacer()
          }
        }
        .minimumScaleFactor(0.8)
      }
    } else if entry.signInRequired {
      signInRequiredView
    } else {
      emptyView
    }
  }

  private var signInRequiredView: some View {
    VStack(alignment: .leading, spacing: 2) {
      HStack(alignment: .center) {
        Circle()
          .frame(width: 12, height: 12)
          .padding(.top, 2)

        Text("Sign in Required")
          .minimumScaleFactor(0.9)
          .lineLimit(1)
          .fontWeight(.semibold)
      }
			.foregroundStyle(Color.indigo)
			.widgetAccentable()

      HStack {
        Text("Open Buddy on your iPhone to continue")
          .multilineTextAlignment(.leading)
        Spacer()
      }
      .minimumScaleFactor(0.8)
    }
  }

  @ViewBuilder
  var emptyView: some View {
    VStack(alignment: .leading, spacing: 2) {
      HStack(alignment: .center) {
        Circle()
          .frame(width: 12, height: 12)
          .padding(.top, 2)

        Text("No more classes")
          .minimumScaleFactor(0.9)
          .lineLimit(1)
          .fontWeight(.semibold)
      }
			.foregroundStyle(Color.indigo)
			.widgetAccentable()

      HStack {
        Text("Enjoy your day")
          .multilineTextAlignment(.leading)
        Spacer()
      }
      .minimumScaleFactor(0.8)
    }
    Spacer()
  }
}
