//
//  UpcomingClassCircularWidgetView.swift
//  soap
//
//  Created by Soongyu Kwon on 07/10/2025.
//

import SwiftUI

public struct UpcomingClassCircularWidgetView: View {
  var entry: LectureEntry

  public init(entry: LectureEntry) {
    self.entry = entry
  }

  public var body: some View {
    if let start = entry.startDate {
      VStack {
        Image(systemName: "calendar")
        Text(start, style: .time)
      }
    } else if entry.signInRequired {
      signInRequiredView
    } else {
      emptyView
    }
  }

  var signInRequiredView: some View {
    VStack {
      Image(systemName: "arrow.up.right.square")
      Text("Sign in")
    }
  }

  var emptyView: some View {
    VStack {
      Image(systemName: "graduationcap")
      Text("0 left")
    }
  }
}
