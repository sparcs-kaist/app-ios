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
      selectionRow(
        title: String(localized: "My Table", bundle: .module),
        isSelected: selectedTimetableID == nil,
        select: { selectedTimetableID = nil }
      )

      ForEach(timetables) { timetable in
        selectionRow(
          title: timetable.title.isEmpty ? String(localized: "Untitled", bundle: .module) : timetable.title,
          isSelected: selectedTimetableID == timetable.id,
          select: { selectedTimetableID = timetable.id }
        )
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
				
        #if os(macOS)
        Image(systemName: "chevron.down")
        #else
        Image(systemName: "ellipsis")
        #endif
      }
      .padding(12)
      .padding(.horizontal, 4)
      .contentShape(.rect)
    })
    #if os(macOS)
    // macOS defaults to the bordered button menu style, which forces the menu
    // into standard control metrics and squashes the label's padding, making the
    // selector shorter than SemesterSelector. Rendering it as a plain button
    // lets the label size itself the same way.
    .menuStyle(.button)
    .buttonStyle(.plain)
    // The chevron in the label replaces the style's own indicator.
    .menuIndicator(.hidden)
    .fixedSize()
    // macOS hides icons of menu items built from a Label unless asked otherwise.
    .labelStyle(.titleAndIcon)
    #else
    // The menu-wide tint is only for the label; on macOS it would also override
    // the red the system gives the destructive Delete item, and the plain menu
    // style already draws the label in the primary color there.
    .tint(.primary)
    #endif
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

  /// A row that selects a timetable and shows a checkmark when it is current.
  @ViewBuilder
  private func selectionRow(
    title: String,
    isSelected: Bool,
    select: @escaping () -> Void
  ) -> some View {
    #if os(macOS)
    // A checkmark placed inside the button's label isn't rendered by AppKit
    // menus, but a Toggle gets the native checkmark gutter for free.
    Toggle(title, isOn: Binding(
      get: { isSelected },
      set: { isOn in
        if isOn {
          select()
        }
      }
    ))
    #else
    Button(action: select, label: {
      HStack {
        if isSelected {
          Image(systemName: "checkmark")
        }
        Text(title)
      }
    })
    #endif
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
