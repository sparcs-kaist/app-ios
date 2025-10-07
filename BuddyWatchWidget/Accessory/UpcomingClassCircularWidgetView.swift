//
//  UpcomingClassCircularWidgetView.swift
//  soap
//
//  Created by Soongyu Kwon on 07/10/2025.
//

import SwiftUI

struct UpcomingClassCircularWidgetView: View {
  var entry: LectureEntry

  var body: some View {
    if let start = entry.startDate {
      VStack {
        Image(systemName: "calendar")
        Text(start, style: .time)
      }
    } else if entry.signInRequired {
      VStack {
        Image(systemName: "arrow.up.right.square")
        Text("Sign in")
      }
    } else {
      VStack {
        Image(systemName: "graduationcap")
        Text("0 left")
      }
    }
  }
}
