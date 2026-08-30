//
//  TableSelector.swift
//  BuddyFeature
//
//  Created by Soongyu Kwon on 8/30/26.
//

import Foundation
import SwiftUI
import BuddyDomain

struct TableSelector: View {
  let timetables: [TimetableSummary]
  @Binding var selectedTimetableID: Int?
  let createTimetable: () async -> Void
  let renameTimetable: (String) async -> Void
  let deleteTimetable: () async -> Void

  @State private var showRenameAlert: Bool = false
  @State private var renameText: String = ""

  var body: some View {
    Menu(content: {
      Button(action: {
        selectedTimetableID = nil
      }, label: {
        HStack {
          if selectedTimetableID == nil {
            Image(systemName: "checkmark")
          }
          Text("My Table", bundle: .module)
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
            Text(timetable.title.isEmpty ? String(localized: "Untitled", bundle: .module) : timetable.title)
          }
        })
      }
			
			#if os(macOS)
			Divider()
			#endif

      Button(String(localized: "New Table", bundle: .module), systemImage: "plus") {
        Task {
          await createTimetable()
        }
      }

      Divider()

      Button(String(localized: "Rename", bundle: .module), systemImage: "square.and.pencil") {
        showRenameAlert = true
      }
      .disabled(selectedTimetableID == nil)

      Button(String(localized: "Delete", bundle: .module), systemImage: "trash", role: .destructive) {
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
				
				#if !os(macOS)
        Image(systemName: "ellipsis")
				#endif
      }
      .padding(12)
      .padding(.horizontal, 4)
      .contentShape(.rect)
    })
    .tint(.primary)
    .glassEffect(.regular.interactive())
    .alert(String(localized: "Rename \"\(displayName)\"", bundle: .module), isPresented: $showRenameAlert, actions: {
      TextField(displayName, text: $renameText)

      Button(String(localized: "Confirm", bundle: .module), role: .confirm, action: {
        Task {
          await renameTimetable(renameText)
          renameText = ""
        }
      })
      .disabled(renameText.isEmpty)

      Button(String(localized: "Cancel", bundle: .module), role: .cancel, action: {})
    }, message: {
      Text("Enter a new name for this timetable.", bundle: .module)
    })
  }

  private var displayName: String {
    guard let timetable = selectedTimetable else {
      return String(localized: "My Table", bundle: .module)
    }
    return timetable.title.isEmpty ? String(localized: "Untitled", bundle: .module) : timetable.title
  }

  private var selectedTimetable: TimetableSummary? {
    timetables.first(where: { $0.id == selectedTimetableID })
  }
}
