//
//  LectureSummary.swift
//  soap
//
//  Created by 하정우 on 9/30/25.
//

import SwiftUI
import BuddyDomain

struct LectureSummary: View {
  let lecture: Lecture

  var body: some View {
    HStack {
      Spacer()
      LectureSummaryRow(title: String(localized: "Language", bundle: .module), description: lecture.isEnglish ? "EN" : "한")
      Spacer()
      LectureSummaryRow(
        title: String(localized: "Credits", bundle: .module),
        description: String(lecture.credit + lecture.creditAU)
      )
      Spacer()
      LectureSummaryRow(
        title: String(localized: "Competition", bundle: .module),
        description: (lecture.capacity == 0 || lecture.enrolledCount == 0)
        ?
        "0.0:1"
        :
          String(
            format: "%.1f",
            Float(lecture.enrolledCount) / Float(lecture.capacity)
          ) + ":1"
      )
      Spacer()
    }
  }
}

//#Preview {
//  LectureSummary(lecture: .mock)
//}
