//
//  TimetableThemeSettingsView.swift
//  BuddyFeature
//
//  Created by Soongyu Kwon on 14/09/2026.
//

import SwiftUI
import BuddyDomain
import TimetableUI
import FirebaseAnalytics

/// `sheet(item:)` needs an identity to present against, and a share code is its
/// own identity.
private struct TimetableThemeImportRequest: Identifiable {
  let id: String
}

public struct TimetableThemeSettingsView: View {
  @State private var viewModel: TimetableThemeSettingsViewModel
  @State private var isCodePromptPresented = false
  @State private var isInvalidCodePresented = false
  @State private var importCode = ""
  @State private var importRequest: TimetableThemeImportRequest?
  @State private var editingTheme: TimetableTheme?
  @State private var themePendingDeletion: TimetableTheme?
  @State private var sharingTheme: TimetableTheme?

  private let sampleTimetable = TimetableThemeSample.timetable

  public init(_ viewModel: TimetableThemeSettingsViewModel = .init()) {
    self.viewModel = viewModel
  }

  public var body: some View {
    List {
      Section {
        preview
      }

      Section {
        ForEach(viewModel.builtInThemes) { theme in
          themeRow(theme)
        }
      } header: {
        Text("Collections", bundle: .module)
      }

      Section {
        ForEach(viewModel.customThemes) { theme in
          themeRow(theme)
        }

        Button(String(localized: "New Theme", bundle: .module), systemImage: "plus") {
          // Starts from whatever is on screen, so the editor opens on the colours
          // the user is already looking at rather than resetting to the default.
          editingTheme = viewModel.selectedTheme.duplicated(
            named: String(localized: "My Theme", bundle: .module)
          )
        }

        Button(String(localized: "Import Theme via Code", bundle: .module), systemImage: "square.and.arrow.down") {
          importCode = ""
          isCodePromptPresented = true
        }
        .accessibilityIdentifier("theme.import")
      } header: {
        Text("My Themes", bundle: .module)
      } footer: {
        Text("Themes in Collections cannot be edited. Duplicate one to start your own.", bundle: .module)
      }
    }
    .navigationTitle(Text("Timetable Theme", bundle: .module))
    .alert(Text("Import Theme", bundle: .module), isPresented: $isCodePromptPresented) {
      TextField(String(localized: "6-character code", bundle: .module), text: $importCode)
        .accessibilityIdentifier("theme.codeInput")
        .textInputAutocapitalization(.characters)
        .autocorrectionDisabled()
        .keyboardType(.asciiCapable)
      Button(String(localized: "Cancel", bundle: .module), role: .cancel) { }
      Button(String(localized: "Continue", bundle: .module)) { submitImportCode() }
        .accessibilityIdentifier("theme.find")
        .disabled(TimetableThemeShareCode.normalized(importCode) == nil)
    } message: {
      Text("Enter the code from the theme you want to import.", bundle: .module)
    }
    // Outside the alert: modifiers on its content aren't guaranteed to run, and
    // the field is the only thing writing to this state anyway.
    .onChange(of: importCode) { _, newValue in
      let sanitized = sanitizedImportCode(newValue)
      if sanitized != importCode { importCode = sanitized }
    }
    .alert(Text("Invalid Code", bundle: .module), isPresented: $isInvalidCodePresented) {
      Button(String(localized: "OK", bundle: .module), role: .cancel) { }
    } message: {
      Text("Theme codes are 6 letters or numbers. Check the code and try again.", bundle: .module)
    }
    // Like sharing, the lookup happens inside the sheet so it reports its own
    // progress and failures rather than blocking this list.
    .sheet(item: $importRequest) { request in
      TimetableThemeImportView(code: request.id) { theme in
        viewModel.saveAndSelect(theme)
      }
    }
    // The upload happens inside the sheet, so it appears immediately and reports
    // its own progress and failures rather than blocking this list.
    .sheet(item: $sharingTheme) { theme in
      TimetableThemeSharingView(theme: theme)
    }
    .sheet(item: $editingTheme) { theme in
      NavigationStack {
        TimetableThemeEditorView(theme: theme, sampleTimetable: sampleTimetable) { edited in
          viewModel.saveAndSelect(edited)
        }
      }
      .presentationDragIndicator(.visible)
    }
    .confirmationDialog(
      Text("Delete Theme", bundle: .module),
      isPresented: Binding(
        get: { themePendingDeletion != nil },
        set: { if !$0 { themePendingDeletion = nil } }
      ),
      titleVisibility: .visible,
      presenting: themePendingDeletion
    ) { theme in
      Button(String(localized: "Delete", bundle: .module), role: .destructive) {
        viewModel.delete(theme)
      }
    } message: { theme in
      Text("“\(theme.displayName)” will be removed, and any widget using it falls back to the default.", bundle: .module)
    }
    .onAppear { viewModel.reload() }
    .analyticsScreen(name: "TimetableTheme", class: String(describing: Self.self))
  }

  // MARK: - Import

  /// Share codes are six upper-cased ASCII letters and digits, so anything else
  /// never reaches the field rather than being rejected after the fact.
  private func sanitizedImportCode(_ input: String) -> String {
    String(input.filter { $0.isASCII && ($0.isLetter || $0.isNumber) }.prefix(6)).uppercased()
  }

  /// The code is only shape-checked here; whether a theme actually exists
  /// behind it is the sheet's job to find out.
  ///
  /// Both presentations are deferred by a turn: presenting straight from the
  /// prompt's button races its own dismissal, which drops whatever comes next.
  private func submitImportCode() {
    guard let code = TimetableThemeShareCode.normalized(importCode) else {
      Task { isInvalidCodePresented = true }
      return
    }
    Task { importRequest = TimetableThemeImportRequest(id: code) }
  }

  // MARK: - Preview

  private var preview: some View {
    ThemedSampleGrid(theme: viewModel.selectedTheme, timetable: sampleTimetable)
      .accessibilityLabel(Text("Timetable preview using \(viewModel.selectedTheme.displayName)", bundle: .module))
  }

  // MARK: - Rows

  private func themeRow(_ theme: TimetableTheme) -> some View {
    Button {
      viewModel.select(theme)
    } label: {
      HStack(spacing: 12) {
        Image(systemName: "checkmark")
          .font(.footnote.weight(.semibold))
          .opacity(viewModel.selectedThemeID == theme.id ? 1 : 0)

        Text(theme.displayName)
          .lineLimit(1)

        Spacer(minLength: 12)

        ThemeSwatchStrip(theme: theme)
      }
      .contentShape(.rect)
    }
    .accessibilityIdentifier("theme.row.\(theme.id)")
    .accessibilityValue(viewModel.selectedThemeID == theme.id ? "selected" : "")
    .foregroundStyle(.primary)
    .accessibilityAddTraits(viewModel.selectedThemeID == theme.id ? [.isButton, .isSelected] : .isButton)
    .contextMenu {
      Button(String(localized: "Share Theme", bundle: .module), systemImage: "square.and.arrow.up") {
        sharingTheme = theme
      }
      if !theme.isBuiltIn {
        Button(String(localized: "Edit", bundle: .module), systemImage: "pencil") {
          editingTheme = theme
        }
      }
      Button(String(localized: "Duplicate", bundle: .module), systemImage: "plus.square.on.square") {
        editingTheme = viewModel.duplicate(theme)
      }
      if !theme.isBuiltIn {
        Button(String(localized: "Delete", bundle: .module), systemImage: "trash", role: .destructive) {
          themePendingDeletion = theme
        }
      }
    }
    .swipeActions(edge: .trailing) {
      if !theme.isBuiltIn {
        Button(String(localized: "Delete", bundle: .module), systemImage: "trash", role: .destructive) {
          themePendingDeletion = theme
        }
        Button(String(localized: "Edit", bundle: .module), systemImage: "pencil") {
          editingTheme = theme
        }
        .tint(.accentColor)
        Button(String(localized: "Share", bundle: .module), systemImage: "square.and.arrow.up") {
          sharingTheme = theme
        }
        .tint(.blue)
      }
    }
  }
}

/// The sample week under a given theme. Shared by the theme list and the editor
/// so both preview identically, including an opted-in background colour.
struct ThemedSampleGrid: View {
  let theme: TimetableTheme
  let timetable: Timetable

  var body: some View {
    TimetableGrid(
      selectedTimetable: timetable,
      beginTime: TimetableThemeSample.beginTime,
      endTime: TimetableThemeSample.endTime,
      placement: .view
    )
    .timetableTheme(theme)
    .frame(height: 280)
    .padding(8)
    .background {
      if let background = theme.backgroundColor {
        RoundedRectangle(cornerRadius: 16).fill(background)
      }
    }
  }
}

/// The colours of a theme, shown compactly on the trailing edge of its row.
struct ThemeSwatchStrip: View {
  let theme: TimetableTheme
  var maximumCount: Int = 7

  var body: some View {
    HStack(spacing: -6) {
      ForEach(Array(theme.colors.prefix(maximumCount).enumerated()), id: \.offset) { _, color in
        Circle()
          .fill(color)
          .overlay(Circle().strokeBorder(.background, lineWidth: 1.5))
          .frame(width: 18, height: 18)
      }
    }
    .accessibilityHidden(true)
  }
}

#Preview {
  NavigationStack {
    TimetableThemeSettingsView()
  }
}
