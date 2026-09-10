//
//  UpcomingClassInlineWidgetView.swift
//  soap
//
//  Created by Soongyu Kwon on 07/10/2025.
//

import Foundation
import SwiftUI
import BuddyDomain

public struct UpcomingClassInlineWidgetView: View {
  var entry: LectureEntry

  public init(entry: LectureEntry) {
    self.entry = entry
  }

  public var body: some View {
    if let title = entry.title, let start = entry.startDate {
      Text("\(start, style: .time) • \(title)")
    } else if entry.signInRequired {
      Text("Sign in Required", bundle: .module)
    } else {
      Text("No more classes", bundle: .module)
    }
  }
}
