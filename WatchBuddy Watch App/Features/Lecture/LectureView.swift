//
//  LectureView.swift
//  soap
//
//  Created by Soongyu Kwon on 06/10/2025.
//

import SwiftUI
import BuddyDomain

struct LectureView: View {
  let entry: ScheduleEntry

  var body: some View {
    VStack(alignment: .leading) {
      HStack(alignment: .top) {
        Circle()
          .frame(width: 12, height: 12)
          .foregroundStyle(entry.backgroundColor)
          .padding(.top, 4)

        Text(entry.title)
          .font(.headline)
          .lineLimit(4)
          .minimumScaleFactor(0.8)

        Spacer()
      }

      Spacer()

      TimelineView(.everyMinute) { context in
        Text(entry.classTime.statusString(at: context.date))
          .foregroundStyle(entry.backgroundColor)
          .font(.caption)
      }
      Text(entry.location)
        .lineLimit(1)
        .minimumScaleFactor(0.8)
    }
    .padding()
  }
}

#Preview {
  LectureView(entry: .lecture(LectureItem.mock))
}
