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
      HStack {
        semesterSelector

        Spacer()

        tableSelector
      }
    }
    .frame(height: 30)
    .task {
      await timetableViewModel.fetchData()
    }
  }

  var tableSelector: some View {
    Menu(content: {
      Button("My Table", systemImage: "checkmark") { }

      Button("New Table", systemImage: "plus") { }

      Divider()
      Button("Delete", systemImage: "trash", role: .destructive) { }
        .tint(nil)
        .disabled(true)
    }, label: {
      HStack(spacing: 16) {
        Text("My Table")
          .fontWeight(.semibold)

        Image(systemName: "ellipsis")
      }
      .padding(12)
      .padding(.horizontal, 4)
      .contentShape(.rect)
    })
    .tint(.primary)
    .glassEffect(.regular.interactive())
  }

  private var semesterSelector: some View {
    HStack {
      Button(action: {
        withAnimation(.spring) {
          timetableViewModel.selectPreviousSemester()
        }
      }, label: {
        Image(systemName: "chevron.left")
      })
      .tint(.black)
      .disabled(timetableViewModel.semesters.first == timetableViewModel.selectedSemester)

      Spacer()

      Text(timetableViewModel.selectedSemester?.description ?? "Unknown")
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
      .disabled(timetableViewModel.semesters.last == timetableViewModel.selectedSemester)
    }
    .frame(maxWidth: 160)
    .fontWeight(.semibold)
    .padding(12)
    .padding(.horizontal, 4)
    .glassEffect(.regular.interactive())
  }
}

#Preview {
  CompactTimetableSelector()
    .environment(TimetableViewModel())
    .background(
      Color(UIColor.secondarySystemBackground)
    )
}

