//
//  TimetableThemeEditorView.swift
//  BuddyFeature
//
//  Created by Soongyu Kwon on 14/09/2026.
//

import SwiftUI
import PhotosUI
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

  /// A theme carries 1–16 colours. Courses cycle through them in order, so a
  /// single colour is a valid (if monotone) theme and an empty one is not.
  private static let minimumColors = 1
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
  @State private var selectedPhoto: PhotosPickerItem?
  @State private var isGeneratingPalette = false
  @State private var isPhotoErrorPresented = false
  @State private var generatedPaletteCount = 0
  @State private var isGeneratorPresented = false
  /// Lives here rather than in the sheet, because whether the description row
  /// is offered at all depends on the model being available.
  @State private var generatorViewModel = TimetableThemeGeneratorViewModel()

  /// The last version handed to `onSave`, seeded with the theme as it was
  /// opened so merely opening and closing the editor writes nothing.
  @State private var savedTheme: TimetableTheme

  private let themeID: String

  init(
    theme: TimetableTheme,
    sampleTimetable: Timetable,
    onSave: @escaping (TimetableTheme) -> Void
  ) {
    self.themeID = theme.id
    self.sampleTimetable = sampleTimetable
    self.onSave = onSave
    self._savedTheme = State(initialValue: theme)
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
    ScrollViewReader { proxy in
      editorList
        .onChange(of: generatedPaletteCount) {
          withAnimation {
            proxy.scrollTo("theme.preview", anchor: .top)
          }
        }
    }
  }

  private var editorList: some View {
    List {
      Section {
        ThemedSampleGrid(theme: draft, timetable: sampleTimetable)
          .id("theme.preview")
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
          .deleteDisabled(colors.count <= Self.minimumColors)
        }
        .onMove(perform: moveItems)
        .onDelete(perform: deleteItems)

        Button {
          addColor()
        } label: {
          Label(String(localized: "Add Colour", bundle: .module), systemImage: "plus")
            .foregroundStyle(canAddColor ? Color.accentColor : Color.secondary)
        }
        .disabled(!canAddColor)
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
      } footer: {
        Text("Add up to 16 colours. Courses are assigned them in order, repeating as needed.", bundle: .module)
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

      Section {
        PhotosPicker(selection: $selectedPhoto, matching: .images) { [isGeneratingPalette] in
          HStack {
            Label(String(localized: "Generate using a Photo", bundle: .module), systemImage: "photo")
            Spacer()
            if isGeneratingPalette {
              ProgressView()
                .accessibilityLabel(Text("Generating Colours…", bundle: .module))
            }
          }
        }
        .accessibilityIdentifier("theme.generateFromPhoto")

        if generatorViewModel.isModelAvailable {
          Button {
            isGeneratorPresented = true
          } label: {
            // Apple's own mark, which SF Symbols allows only in reference to
            // the technology itself. That is what this is: the row drives
            // `SystemLanguageModel`, and it is only shown when Apple
            // Intelligence is actually available.
            Label(String(localized: "Generate using Apple Intelligence", bundle: .module), systemImage: "apple.intelligence")
          }
          .accessibilityIdentifier("theme.generateFromDescription")
        }
      } footer: {
        if generatorViewModel.isModelAvailable {
          Text("Use a wallpaper, a photo or a few words to replace the palette, text and advanced colours with a matching theme. Everything happens on your device.", bundle: .module)
        } else {
          Text("Use a wallpaper or photo to replace the palette, text and advanced colours with a matching theme.", bundle: .module)
        }
      }
    }
		.disabled(isGeneratingPalette)
		.listStyle(.insetGrouped)
		.environment(\.editMode, .constant(isEditingSection ? .active : .inactive))
    .navigationTitle(Text("Theme", bundle: .module))
    .toolbar {
      ToolbarItem(placement: .confirmationAction) {
        Button(role: .confirm) {
          // Unconditional, unlike the autosaves below: a theme opened from
          // Duplicate isn't in the store yet, so confirming has to write it
          // even when nothing was edited.
          persist()
          dismiss()
        }
        .disabled(!draft.isValid || isGeneratingPalette)
      }
    }
    .task(id: selectedPhoto) {
      guard let photo = selectedPhoto else { return }
      await generatePalette(from: photo)
    }
    // Asked once per editor, because the answer changes with a Settings toggle
    // and a model download rather than with anything happening here.
    .task { await generatorViewModel.refreshAvailability() }
    .sheet(isPresented: $isGeneratorPresented) {
      TimetableThemeGeneratorView(baseTheme: draft, onApply: apply, viewModel: generatorViewModel)
    }
    .alert(Text("Couldn't Generate Theme", bundle: .module), isPresented: $isPhotoErrorPresented) {
      Button(String(localized: "OK", bundle: .module), role: .cancel) { }
    } message: {
      Text("The photo couldn't be read. Please try again or choose another photo.", bundle: .module)
    }
    // Edits are saved as they happen, so there is nothing to cancel and
    // leaving by swipe keeps the changes too. The sleep coalesces a burst of
    // edits — typing a name, dragging a colour picker — into one write, and
    // `task(id:)` cancels the pending save whenever the draft changes again.
    .task(id: draft) {
      guard hasUnsavedChanges else { return }
      try? await Task.sleep(for: .milliseconds(500))
      guard !Task.isCancelled else { return }
      persist()
    }
    // The debounce can still be pending when the sheet is swiped away, which
    // cancels the task above before it gets to write.
    .onDisappear {
      guard hasUnsavedChanges else { return }
      persist()
    }
  }

  /// An invalid draft — a blank name, no colours — is left unsaved rather than
  /// overwriting the last good version.
  private var hasUnsavedChanges: Bool {
    draft != savedTheme && draft.isValid
  }

  private func persist() {
    onSave(draft)
    savedTheme = draft
  }

  private func generatePalette(from photo: PhotosPickerItem) async {
    isGeneratingPalette = true
    defer {
      isGeneratingPalette = false
      selectedPhoto = nil
    }

    do {
      guard let data = try await photo.loadTransferable(type: Data.self) else {
        throw TimetablePhotoPalette.GenerationError.unreadableImage
      }
      let palette = try await TimetablePhotoPalette.generate(from: data)
      try Task.checkCancellation()
      apply(palette)
    } catch {
      guard !Task.isCancelled else { return }
      isPhotoErrorPresented = true
    }
  }

  /// Replaces every colour the palette covers, and opts the theme into the
  /// three it only carries when asked to — a generated theme is a whole look,
  /// not a new set of cells dropped into the old grid.
  private func apply(_ palette: TimetablePalette) {
    colors = palette.colors.map { ColorItem(color: Color(hex: $0)) }
    textColor = Color(hex: palette.text)
    backgroundColor = Color(hex: palette.background)
    separatorColor = Color(hex: palette.separator)
    gridLabelColor = Color(hex: palette.gridLabel)
    usesCustomBackground = true
    usesCustomSeparator = true
    usesCustomGridLabel = true
    isEditingSection = false
    generatedPaletteCount += 1
  }

  /// A described theme also arrives with a name, which is the one thing a
  /// photo cannot offer.
  private func apply(_ theme: TimetableTheme) {
    apply(TimetablePalette(
      colors: theme.hexColors,
      text: theme.textColorHex,
      background: theme.backgroundColorHex ?? backgroundColor.hexString,
      separator: theme.separatorColorHex ?? separatorColor.hexString,
      gridLabel: theme.gridLabelColorHex ?? gridLabelColor.hexString
    ))
    name = theme.name
  }
	
  private var canAddColor: Bool {
    colors.count < Self.maximumColors
  }

  private func addColor() {
    guard colors.count < Self.maximumColors else { return }
    let palette = TimetableTheme.default.colors
    let seed = palette.isEmpty ? .accentColor : palette[colors.count % palette.count]
    withAnimation {
      colors.append(ColorItem(color: seed))
    }
  }

  private func deleteItems(at offsets: IndexSet) {
    guard colors.count - offsets.count >= Self.minimumColors else { return }
    colors.remove(atOffsets: offsets)
  }

  private func moveItems(from source: IndexSet, to destination: Int) {
    colors.move(fromOffsets: source, toOffset: destination)
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
    guard colors.count > Self.minimumColors, colors.indices.contains(index) else { return }
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

/// A three-colour theme: cells cycle through the short palette rather than
/// needing a full sixteen.
#Preview("Short palette") {
  NavigationStack {
    TimetableThemeEditorView(
      theme: TimetableTheme(
        id: "custom.preview.short",
        name: "Trio",
        hexColors: ["307878", "E34B6C", "C3BA0A"],
        textColorHex: "FFFFFF"
      ),
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
