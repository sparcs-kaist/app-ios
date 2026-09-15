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

public struct TimetableThemeSettingsView: View {
  @State private var viewModel: TimetableThemeSettingsViewModel
  @State private var isImportPresented = false
  @State private var importCode = ""
  @State private var editingTheme: TimetableTheme?
  @State private var themePendingDeletion: TimetableTheme?

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
      } header: {
        Text("My Themes", bundle: .module)
      } footer: {
        Text("Themes in Collections cannot be edited. Duplicate one to start your own.", bundle: .module)
      }
    }
    .navigationTitle(Text("Timetable Theme", bundle: .module))
    .toolbar {
      ToolbarItem(placement: .topBarTrailing) {
        Button {
          importCode = ""
          viewModel.importedTheme = nil
          viewModel.sharingError = nil
          isImportPresented = true
        } label: {
          Label(String(localized: "Import Theme", bundle: .module), systemImage: "square.and.arrow.down")
        }
        .accessibilityIdentifier("theme.import")
        .disabled(viewModel.isSharing)
      }
    }
    .overlay {
      if viewModel.isSharing { ProgressView() }
    }
    .sheet(isPresented: $isImportPresented) {
      NavigationStack {
        List {
          Section {
            TextField(String(localized: "6-character code", bundle: .module), text: $importCode)
              .accessibilityIdentifier("theme.codeInput")
              .textInputAutocapitalization(.characters)
              .autocorrectionDisabled()
              .keyboardType(.asciiCapable)
              .disabled(viewModel.isImporting)
              .onChange(of: importCode) { viewModel.importedTheme = nil }
            Button(String(localized: "Find Theme", bundle: .module)) {
              Task { await viewModel.fetchSharedTheme(code: importCode) }
            }
            .accessibilityIdentifier("theme.find")
            .disabled(TimetableThemeShareCode.normalized(importCode) == nil || viewModel.isImporting)
            if viewModel.isImporting { ProgressView() }
          }
          if let theme = viewModel.importedTheme {
            Section {
              Text(theme.name)
              ThemedSampleGrid(theme: theme, timetable: sampleTimetable)
              Button(String(localized: "Save and Use Theme", bundle: .module)) {
                viewModel.saveAndSelect(theme)
                isImportPresented = false
              }
              .accessibilityIdentifier("theme.saveImport")
            }
          }
          if let error = viewModel.sharingError {
            Text(error).foregroundStyle(.red)
          }
        }
        .navigationTitle(Text("Import Theme", bundle: .module))
        .toolbar {
          ToolbarItem(placement: .cancellationAction) {
            Button(String(localized: "Cancel", bundle: .module)) { isImportPresented = false }
              .disabled(viewModel.isImporting)
          }
        }
      }
      .interactiveDismissDisabled(viewModel.isImporting)
    }
    .sheet(isPresented: Binding(
      get: { viewModel.sharedCode != nil },
      set: { if !$0 { viewModel.sharedCode = nil } }
    )) {
      NavigationStack {
        VStack(spacing: 24) {
          Text(viewModel.sharedCode ?? "")
            .accessibilityIdentifier("theme.shareCode")
            .font(.largeTitle.monospaced().bold())
            .textSelection(.enabled)
          Text("Enter this code in Import Theme on another device.", bundle: .module)
            .multilineTextAlignment(.center)
          ShareLink(item: viewModel.sharedCode ?? "")
        }
        .padding()
        .navigationTitle(Text("Share Theme", bundle: .module))
        .toolbar {
          ToolbarItem(placement: .confirmationAction) {
            Button(String(localized: "Done", bundle: .module)) { viewModel.sharedCode = nil }
          }
        }
      }
      .presentationDetents([.medium])
    }
    .alert(Text("Theme Sharing", bundle: .module), isPresented: Binding(
      get: { viewModel.sharingError != nil && !isImportPresented },
      set: { if !$0 { viewModel.sharingError = nil } }
    )) {
      Button(String(localized: "OK", bundle: .module), role: .cancel) { viewModel.sharingError = nil }
    } message: {
      Text(viewModel.sharingError ?? "")
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
        Task { await viewModel.share(theme) }
      }
      .disabled(viewModel.isSharing)
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
          Task { await viewModel.share(theme) }
        }
        .tint(.blue)
        .disabled(viewModel.isSharing)
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
