//
//  CompactTimetableSelector.swift
//  soap
//
//  Created by Soongyu Kwon on 05/01/2025.
//

import SwiftUI
import Haptica
import BuddyDomain

struct CompactTimetableSelector: View {
  let semesters: [Semester]
  @Binding var selectedSemester: Semester?
  let timetables: [V2TimetableSummary]
  @Binding var selectedTimetableID: Int?
  let renameTimetable: (String) async -> Void
  let deleteTimetable: () async -> Void

  @State private var showRenameAlert: Bool = false
  @State private var renameText: String = ""

  var body: some View {
    ZStack {
      HStack {
        semesterSelector

        Spacer()

        tableSelector
      }
    }
    .frame(height: 30)
    .alert("Rename \"\(displayName)\"", isPresented: $showRenameAlert, actions: {
      TextField(displayName, text: $renameText)

      Button("Confirm", role: .confirm, action: {
        Task {
          await renameTimetable(renameText)
          renameText = ""
        }
      })
      .disabled(renameText.isEmpty)

      Button("Cancel", role: .cancel, action: {})
    }, message: {
      Text("Enter a new name for this timetable.")
    })
  }

  var tableSelector: some View {
    Menu(content: {
      Button(action: {
        selectedTimetableID = nil
      }, label: {
        HStack {
          if selectedTimetableID == nil {
            Image(systemName: "checkmark")
          }
          Text("My Table")
        }
      })

      ForEach(timetables) { timetable in
        Button(action: {
          selectedTimetableID = timetable.id
        }, label: {
          HStack {
            if selectedTimetableID == timetable.id {
              Image(systemName: "checkmark")
            }
            Text(timetable.title.isEmpty ? "Untitled" : timetable.title)
          }
        })
      }

      Button("New Table", systemImage: "plus") {
        Task {
//          await timetableViewModel.createTable()
        }
      }

      Divider()

      Button("Rename", systemImage: "square.and.pencil") {
        showRenameAlert = true
      }
      .disabled(selectedTimetableID == nil)

      Button("Delete", systemImage: "trash", role: .destructive) {
        Task {
          await deleteTimetable()
        }
      }
      .tint(nil)
      .disabled(selectedTimetableID == nil)
    }, label: {
      HStack(spacing: 16) {
        Text(displayName)
          .fontWeight(.semibold)
          .contentTransition(.numericText())

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
        Haptic.decrease.generate()
        selectPreviousSemester()
      }, label: {
        Image(systemName: "chevron.left")
      })
      .tint(.primary)
      .disabled(semesters.first == selectedSemester)
      .unredacted()

      Spacer()

      Text(selectedSemester?.description ?? "Unknown")
        .contentTransition(.numericText())
        .animation(.spring, value: selectedSemester?.id)

      Spacer()

      Button(action: {
        Haptic.increase.generate()
        selectNextSemester()
      }, label: {
        Image(systemName: "chevron.right")
      })
      .tint(.primary)
      .disabled(semesters.last == selectedSemester)
      .unredacted()
    }
    .frame(maxWidth: 160)
    .fontWeight(.semibold)
    .padding(12)
    .padding(.horizontal, 4)
    .glassEffect(.regular.interactive())
  }

  private func selectPreviousSemester() {
    guard
      let selectedSemester,
      let currentIndex = semesters.firstIndex(of: selectedSemester),
      currentIndex > 0
    else { return }

    withAnimation(.spring) {
      self.selectedSemester = semesters[currentIndex - 1]
    }
  }

  private func selectNextSemester() {
    guard
      let selectedSemester,
      let currentIndex = semesters.firstIndex(of: selectedSemester),
      currentIndex < semesters.count - 1
    else { return }

    withAnimation(.spring) {
      self.selectedSemester = semesters[currentIndex + 1]
    }
  }

  private var displayName: String {
    guard let timetable = selectedTimetable else {
      return "My Table"
    }
    return timetable.title.isEmpty ? "Untitled" : timetable.title
  }

  private var selectedTimetable: V2TimetableSummary? {
    timetables.first(where: { $0.id == selectedTimetableID })
  }
}

#Preview {
//  CompactTimetableSelector()
//    .environment(TimetableViewModel())
//    .background(
//      Color(UIColor.systemGroupedBackground)
//    )
}

