//
//  LectureSummary.swift
//  soap
//
//  Created by 하정우 on 9/30/25.
//

import SwiftUI

struct LectureSummary: View {
  let lecture: Lecture
  
  var body: some View {
    HStack {
      Spacer()
      LectureSummaryRow(title: "Language", description: lecture.isEnglish ? "EN" : "한")
      Spacer()
      LectureSummaryRow(
        title: "Credits",
        description: String(lecture.credit + lecture.creditAu)
      )
      Spacer()
      LectureSummaryRow(
        title: "Competition",
        description: (lecture.capacity == 0 || lecture.numberOfPeople == 0)
        ?
        "0.0:1"
        :
          String(
            format: "%.1f",
            Float(lecture.numberOfPeople) / Float(lecture.capacity)
          ) + ":1"
      )
      Spacer()
    }
  }
}

#Preview {
  LectureSummary(lecture: .mock)
}
