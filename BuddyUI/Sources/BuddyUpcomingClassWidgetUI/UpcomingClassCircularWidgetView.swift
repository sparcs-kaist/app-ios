//
//  UpcomingClassCircularWidgetView.swift
//  soap
//
//  Created by Soongyu Kwon on 07/10/2025.
//

import Foundation
import SwiftUI

public struct UpcomingClassCircularWidgetView: View {
  var entry: LectureEntry

  public init(entry: LectureEntry) {
    self.entry = entry
  }

  public var body: some View {
		if let start = entry.startDate, let _ = entry.lecture {
			VStack(spacing: 4) {
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
		VStack(spacing: 4) {
      Image(systemName: "arrow.up.right.square")
      Text(String(localized: "Sign in", bundle: .module))
    }
  }

  var emptyView: some View {
		VStack(spacing: 4) {
      Image(systemName: "graduationcap")
      Text(String(localized: "0 left", bundle: .module))
    }
  }
}
