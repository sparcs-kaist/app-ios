//
//  TimetableThemeEditorView.swift
//  BuddyFeature
//
//  Created by Soongyu Kwon on 14/09/2026.
//

import SwiftUI
import BuddyDomain
import TimetableUI

/// Creates or edits one of the user's own themes. Provided themes reach this
/// screen only as a duplicate, so everything here is always editable.
struct TimetableThemeEditorView: View {
  @Environment(\.dismiss) private var dismiss

  private static let maximumColors = 16

  let sampleTimetable: Timetable
  let onSave: (TimetableTheme) -> Void

  @State private var name: String
  @State private var colors: [Color]
  @State private var textColor: Color

  private let themeID: String

  init(
    theme: TimetableTheme,
    sampleTimetable: Timetable,
    onSave: @escaping (TimetableTheme) -> Void
  ) {
    self.themeID = theme.id
    self.sampleTimetable = sampleTimetable
    self.onSave = onSave
    self._name = State(initialValue: theme.name)
    self._colors = State(initialValue: theme.colors)
    self._textColor = State(initialValue: theme.textColor)
  }

  var body: some View {
    List {
      Section {
        TimetableGrid(
          selectedTimetable: sampleTimetable,
          beginTime: TimetableThemeSample.beginTime,
          endTime: TimetableThemeSample.endTime,
          placement: .view
        )
        .timetableTheme(draft)
        .frame(height: 280)
        .padding(.vertical, 8)
      } header: {
        Text("Preview", bundle: .module)
      }

      Section {
        TextField(String(localized: "Name", bundle: .module), text: $name)
        ColorPicker(String(localized: "Text Colour", bundle: .module), selection: $textColor, supportsOpacity: false)
      }

      Section {
        colorGrid

        Button(String(localized: "Add Colour", bundle: .module), systemImage: "plus") {
          colors.append(colors.last ?? .accentColor)
        }
        .disabled(colors.count >= Self.maximumColors)
      } header: {
        Text("Class Colours", bundle: .module)
      } footer: {
        Text("Classes take colours from this list in order, so the same class always keeps its colour.", bundle: .module)
      }
    }
    .navigationTitle(Text("Theme", bundle: .module))
    .toolbar {
      ToolbarItem(placement: .cancellationAction) {
        Button(role: .cancel) { dismiss() }
      }
      ToolbarItem(placement: .confirmationAction) {
        Button(role: .confirm) {
          onSave(draft)
          dismiss()
        }
        .disabled(!draft.isValid)
      }
    }
  }

  private var colorGrid: some View {
    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 4), spacing: 12) {
      ForEach(Array(colors.enumerated()), id: \.offset) { index, _ in
        ColorPicker(
          String(localized: "Colour \(index + 1)", bundle: .module),
          selection: $colors[index],
          supportsOpacity: false
        )
        .labelsHidden()
        .contextMenu {
          Button(String(localized: "Remove", bundle: .module), systemImage: "trash", role: .destructive) {
            remove(at: index)
          }
          .disabled(colors.count <= 1)
        }
      }
    }
    .padding(.vertical, 4)
  }

  private var draft: TimetableTheme {
    TimetableTheme(
      id: themeID,
      name: name,
      hexColors: colors.map(\.hexString),
      textColorHex: textColor.hexString
    )
  }

  private func remove(at index: Int) {
    guard colors.count > 1, colors.indices.contains(index) else { return }
    colors.remove(at: index)
  }
}

#Preview {
  NavigationStack {
    TimetableThemeEditorView(
      theme: .makeCustom(name: "My Theme"),
      sampleTimetable: TimetableThemeSample.timetable
    ) { _ in }
  }
}
