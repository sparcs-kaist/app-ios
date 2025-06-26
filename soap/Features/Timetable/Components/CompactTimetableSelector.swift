//
//  CompactTimetableSelector.swift
//  soap
//
//  Created by Soongyu Kwon on 05/01/2025.
//

import SwiftUI

struct CompactTimetableSelector: View {
  @Environment(TimetableViewModel.self) private var timetableViewModel

  var body: some View {
    ZStack {
      if let selectedTimetable = timetableViewModel.selectedTimetable {
        HStack {
          HStack {
            Button(action: {
              withAnimation(.spring) {
                timetableViewModel.selectPreviousSemester()
              }
            }, label: {
              Image(systemName: "chevron.left")
            })
            .tint(.black)
            .disabled(timetableViewModel.semesters.first == selectedTimetable.semester)

            Spacer()

            Text(selectedTimetable.semester.description)
              .contentTransition(.numericText())

            Spacer()

            Button(action: {
              withAnimation(.spring) {
                timetableViewModel.selectNextSemester()
              }
            }, label: {
              Image(systemName: "chevron.right")
            })
            .tint(.black)
            .disabled(timetableViewModel.semesters.last == selectedTimetable.semester)
          }
          .frame(maxWidth: 160)
          .fontWeight(.semibold)
          .padding(12)
          .glassEffect(.regular.interactive())

          Spacer()

          Button(action: {

          }, label: {
            HStack(spacing: 16) {
              Text("My Table")
                .fontWeight(.semibold)

              Image(systemName: "ellipsis")
            }
          })
          .tint(.primary)
          .padding(12)
          .glassEffect(.regular.interactive())
        }
      }
    }
    .frame(height: 30)
    .task {
      await timetableViewModel.fetchData()
    }
  }
}

#Preview {
  CompactTimetableSelector()
    .environment(TimetableViewModel())
    .background(
      Color(UIColor.secondarySystemBackground)
    )
}

