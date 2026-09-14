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
      } header: {
        Text("Preview", bundle: .module)
      }

      Section {
        ForEach(viewModel.builtInThemes) { theme in
          themeRow(theme)
        }
      } header: {
        Text("Provided", bundle: .module)
      }

      Section {
        ForEach(viewModel.customThemes) { theme in
          themeRow(theme)
        }

        Button(String(localized: "New Theme", bundle: .module), systemImage: "plus") {
          editingTheme = .makeCustom(name: String(localized: "My Theme", bundle: .module))
        }
      } header: {
        Text("My Themes", bundle: .module)
      } footer: {
        Text("Provided themes can't be edited. Duplicate one to start your own.", bundle: .module)
      }
    }
    .navigationTitle(Text("Timetable Theme", bundle: .module))
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
    TimetableGrid(
      selectedTimetable: sampleTimetable,
      beginTime: TimetableThemeSample.beginTime,
      endTime: TimetableThemeSample.endTime,
      placement: .view
    )
    .timetableTheme(viewModel.selectedTheme)
    .frame(height: 280)
    .padding(.vertical, 8)
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
    .foregroundStyle(.primary)
    .accessibilityAddTraits(viewModel.selectedThemeID == theme.id ? [.isButton, .isSelected] : .isButton)
    .contextMenu {
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
