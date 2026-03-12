//
//  LectureView.swift
//  soap
//
//  Created by Soongyu Kwon on 06/10/2025.
//

import SwiftUI
import BuddyDomain

struct LectureView: View {
  let item: V2LectureItem

  var body: some View {
    VStack(alignment: .leading) {
      HStack(alignment: .top) {
        Circle()
          .frame(width: 12, height: 12)
          .foregroundStyle(item.lecture.backgroundColor)
          .padding(.top, 4)

        Text(item.lecture.name)
          .font(.headline)
          .lineLimit(4)
          .minimumScaleFactor(0.8)

        Spacer()
      }

      Spacer()

      TimelineView(.everyMinute) { context in
        Text(item.lectureClass.statusString(at: context.date))
          .foregroundStyle(item.lecture.backgroundColor)
          .font(.caption)
      }
      Text("\(item.lectureClass.buildingCode) \(item.lectureClass.roomName)")
        .lineLimit(1)
        .minimumScaleFactor(0.8)
    }
    .padding()
  }
}

#Preview {
  LectureView(item: V2LectureItem.mock)
}
