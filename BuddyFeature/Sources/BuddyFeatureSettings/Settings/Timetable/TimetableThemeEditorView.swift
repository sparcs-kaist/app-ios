//
//  TimetableThemeEditorView.swift
//  BuddyFeature
//
//  Created by Soongyu Kwon on 14/09/2026.
//

import SwiftUI
import BuddyDomain
import TimetableUI

/// Wraps a palette colour with a stable identity, so rows keep their identity
/// while the colour itself is edited.
struct ColorItem: Identifiable {
  let id = UUID()
  var color: Color
}

struct TimetableThemeEditorView: View {
  @Environment(\.dismiss) private var dismiss

  private static let maximumColors = 16

  let sampleTimetable: Timetable
  let onSave: (TimetableTheme) -> Void

  @State private var name: String
  @State private var colors: [ColorItem]
	@State private var isEditingSection = false
  @State private var textColor: Color

  // Both are opt-in, so the toggle state is what decides whether the theme
  // carries a colour at all — the picker only holds the value to use.
  @State private var usesCustomSeparator: Bool
  @State private var separatorColor: Color
  @State private var usesCustomBackground: Bool
  @State private var backgroundColor: Color
  @State private var usesCustomGridLabel: Bool
  @State private var gridLabelColor: Color
  @State private var isAdvancedExpanded = false

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
    self._colors = State(initialValue: theme.colors.map { ColorItem(color: $0) })
    self._textColor = State(initialValue: theme.textColor)
    self._usesCustomSeparator = State(initialValue: theme.separatorColorHex != nil)
    self._separatorColor = State(initialValue: theme.separatorColor ?? .separator)
    self._usesCustomBackground = State(initialValue: theme.backgroundColorHex != nil)
    self._backgroundColor = State(initialValue: theme.backgroundColor ?? .secondarySystemGroupedBackground)
    self._usesCustomGridLabel = State(initialValue: theme.gridLabelColorHex != nil)
    // Seeds from whatever the labels resolve to today, so turning the toggle on
    // starts from the current appearance rather than an arbitrary colour.
    self._gridLabelColor = State(initialValue: theme.gridLabelColor ?? .label)
  }

  var body: some View {
    List {
      Section {
        ThemedSampleGrid(theme: draft, timetable: sampleTimetable)
      }

      Section {
        TextField(String(localized: "Name", bundle: .module), text: $name)
        ColorPicker(String(localized: "Text Colour", bundle: .module), selection: $textColor, supportsOpacity: false)
      }

      Section {
				ForEach($colors) { $color in
					ColorPicker(
						String(localized: "Colour", bundle: .module),
						selection: $color.color,
						supportsOpacity: false
					)
				}
				.onMove(perform: moveItems)
				.onDelete(perform: deleteItems)
      } header: {
				HStack {
					Text("Palette", bundle: .module)
					
					Spacer()
					
					Button(isEditingSection ? "Done" : "Reorder") {
						withAnimation {
							isEditingSection.toggle()
						}
					}
					.font(.subheadline)
					.textCase(nil)
				}
			}

      Section {
        DisclosureGroup(isExpanded: $isAdvancedExpanded) {
          Toggle(String(localized: "Custom Separator", bundle: .module), isOn: $usesCustomSeparator)
          if usesCustomSeparator {
            ColorPicker(
              String(localized: "Separator Colour", bundle: .module),
              selection: $separatorColor,
              supportsOpacity: false
            )
          }

          Toggle(String(localized: "Custom Background", bundle: .module), isOn: $usesCustomBackground)
          if usesCustomBackground {
            ColorPicker(
              String(localized: "Background Colour", bundle: .module),
              selection: $backgroundColor,
              supportsOpacity: false
            )
          }

          Toggle(String(localized: "Custom Day & Hour Labels", bundle: .module), isOn: $usesCustomGridLabel)
          if usesCustomGridLabel {
            ColorPicker(
              String(localized: "Label Colour", bundle: .module),
              selection: $gridLabelColor,
              supportsOpacity: false
            )
          }
        } label: {
          Text("Advanced", bundle: .module)
        }
      }
    }
		.listStyle(.insetGrouped)
		.environment(\.editMode, .constant(isEditingSection ? .active : .inactive))
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
	
	private func deleteItems(at offsets: IndexSet) {
		colors.remove(atOffsets: offsets)
	}
	
	private func moveItems(from source: IndexSet, to destination: Int) {
		colors.move(fromOffsets: source, toOffset: destination)
	}

  private var colorGrid: some View {
    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 4), spacing: 12) {
      ForEach(Array(colors.enumerated()), id: \.element.id) { index, _ in
        ColorPicker(
          String(localized: "Colour \(index + 1)", bundle: .module),
          selection: $colors[index].color,
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
      hexColors: colors.map(\.color.hexString),
      textColorHex: textColor.hexString,
      separatorColorHex: usesCustomSeparator ? separatorColor.hexString : nil,
      backgroundColorHex: usesCustomBackground ? backgroundColor.hexString : nil,
      gridLabelColorHex: usesCustomGridLabel ? gridLabelColor.hexString : nil
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
      theme: TimetableTheme.default.duplicated(named: "My Theme"),
      sampleTimetable: TimetableThemeSample.timetable
    ) { _ in }
  }
}

/// "New Theme" while Spring is selected: the editor opens on Spring's colours.
#Preview("New theme seeded from selection") {
  NavigationStack {
    TimetableThemeEditorView(
      theme: TimetableTheme.builtIn
        .first { $0.id == "builtin.spring" }!
        .duplicated(named: "My Theme"),
      sampleTimetable: TimetableThemeSample.timetable
    ) { _ in }
  }
}

#Preview("Advanced colours set") {
  NavigationStack {
    TimetableThemeEditorView(
      theme: TimetableTheme(
        id: "custom.preview",
        name: "Midnight",
        hexColors: TimetableTheme.builtIn[8].hexColors,
        textColorHex: "FFFFFF",
        separatorColorHex: "3C5068",
        backgroundColorHex: "0B1622",
        gridLabelColorHex: "7FB2D9"
      ),
      sampleTimetable: TimetableThemeSample.timetable
    ) { _ in }
  }
}
