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
  }

  var tableSelector: some View {
    Menu(content: {
      ForEach(timetableViewModel.timetableIDsForSelectedSemester.enumerated(), id: \.element) { offset, id in
        if id.contains("myTable") {
          Button(action: {
            timetableViewModel.selectTimetable(id: id)
          }, label: {
            HStack {
              if id == timetableViewModel.selectedTimetable?.id {
                Image(systemName: "checkmark")
              }
              Text("My Table")
            }
          })
        } else {
          Button(action: {
            timetableViewModel.selectTimetable(id: id)
          }, label: {
            HStack {
              if id == timetableViewModel.selectedTimetable?.id {
                Image(systemName: "checkmark")
              }
              Text("Table \(offset)")
            }
          })
        }
      }

      Button("New Table", systemImage: "plus") {
        Task {
          do {
            try await timetableViewModel.createTable()
          } catch {
            timetableViewModel.handleException(error: error, type: .createTable)
          }
        }
      }

      Divider()
      Button("Delete", systemImage: "trash", role: .destructive) {
        Task {
          do {
            try await timetableViewModel.deleteTable()
          } catch {
            timetableViewModel.handleException(error: error, type: .deleteTable)
          }
        }
      }
      .tint(nil)
      .disabled(!timetableViewModel.isEditable)
    }, label: {
      HStack(spacing: 16) {
        Text(timetableViewModel.selectedTimetableDisplayName)
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
      .tint(.primary)
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
      .tint(.primary)
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
      Color(UIColor.systemGroupedBackground)
    )
}

