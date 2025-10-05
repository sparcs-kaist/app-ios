//
//  LectureView.swift
//  soap
//
//  Created by Soongyu Kwon on 06/10/2025.
//

import SwiftUI
import BuddyDomain
import BuddyDataMocks

struct LectureView: View {
  let item: LectureItem

  var body: some View {
    VStack(alignment: .leading) {
      HStack(alignment: .top) {
        Circle()
          .frame(width: 12, height: 12)
          .foregroundStyle(item.lecture.backgroundColor)
          .padding(.top, 4)

        Text(item.lecture.title.localized())
          .font(.headline)
          .lineLimit(4)
          .minimumScaleFactor(0.8)

        Spacer()
      }

      Spacer()

      Text(item.lecture.classTimes[item.index].statusString)
        .foregroundStyle(item.lecture.backgroundColor)
        .font(.caption)
      Text(item.lecture.classTimes[item.index].classroomNameShort.localized())
        .lineLimit(1)
        .minimumScaleFactor(0.8)
    }
    .padding()
  }
}

#Preview {
  LectureView(item: LectureItem(lecture: Lecture.mock, index: 0))
}
