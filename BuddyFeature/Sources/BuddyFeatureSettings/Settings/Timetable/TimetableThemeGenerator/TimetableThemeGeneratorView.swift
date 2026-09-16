//
//  TimetableThemeGeneratorView.swift
//  BuddyFeature
//
//  Created by Soongyu Kwon on 16/09/2026.
//

import SwiftUI
import BuddyDomain

struct TimetableThemeGeneratorView: View {
  /// The theme being edited. Supplies the identity a generated theme keeps,
  /// the name to fall back on, and the grid to show before anything has been
  /// generated.
  let baseTheme: TimetableTheme
  /// Called with the generated theme when the person chooses to keep it.
  let onApply: (TimetableTheme) -> Void
  /// Owned by the editor, which needs the same availability answer to decide
  /// whether to offer this sheet at all.
  @Bindable var viewModel: TimetableThemeGeneratorViewModel

  @Environment(\.dismiss) private var dismiss
  @FocusState private var isDescriptionFocused: Bool

  /// Starting points, not presets: tapping one fills the field, so it can be
  /// edited and sent again.
  private static let examples = [
    String(localized: "Cosy autumn café", bundle: .module),
    String(localized: "Midnight neon city", bundle: .module),
    String(localized: "Pastel spring picnic", bundle: .module),
    String(localized: "Deep ocean", bundle: .module),
    String(localized: "Matcha latte", bundle: .module)
  ]

  var body: some View {
    NavigationStack {
			ScrollView {
				VStack(spacing: 16) {
					preview
					
					Spacer(minLength: 0)
					
					status
					
					Spacer(minLength: 0)
					
					examplesStrip
					descriptionField
					actions
				}
			}
			.scrollDismissesKeyboard(.immediately)
      .animation(.smooth, value: viewModel.viewState)
      .animation(.smooth, value: viewModel.previewTheme)
      .padding(.horizontal)
      .padding(.bottom, 8)
      .navigationBarTitleDisplayMode(.inline)
      .navigationTitle(Text("Generate Theme", bundle: .module))
      .toolbar {
        ToolbarItem(placement: .cancellationAction) {
          Button("Close", systemImage: "xmark", role: .close) {
            dismiss()
          }
        }
      }
    }
    .presentationDragIndicator(.visible)
    // Cancels the model mid-sentence when the sheet is dismissed, and when a
    // second run replaces the first.
    .task(id: viewModel.requestID) {
      guard viewModel.requestID > 0 else { return }
      await viewModel.generate(basedOn: baseTheme)
    }
  }

  // MARK: - Preview

  /// The theme as far as it has been written, falling back to the one being
  /// edited so there is always a grid to look at.
  private var preview: some View {
    ThemedSampleGrid(
      theme: viewModel.previewTheme ?? baseTheme,
      timetable: TimetableThemeSample.timetable
    )
    .accessibilityIdentifier("theme.generatedPreview")
  }

  // MARK: - Status

  @ViewBuilder
  private var status: some View {
    switch viewModel.viewState {
    case .idle:
      Text("Describe the colours you want — a mood, a place, a season — and the theme is made on your device.", bundle: .module)
        .font(.footnote)
        .foregroundStyle(.secondary)
        .multilineTextAlignment(.center)
        .transition(.blurReplace)

    case .generating:
      HStack(spacing: 8) {
        ProgressView()
        Text("Choosing colours…", bundle: .module)
          .font(.footnote)
          .foregroundStyle(.secondary)
      }
      .transition(.blurReplace)

    case .ready:
      VStack(spacing: 4) {
        Text(viewModel.previewTheme?.name ?? baseTheme.name)
          .font(.title2)
          .fontWeight(.semibold)
          .accessibilityIdentifier("theme.generatedName")

        Text("Keeping this replaces the palette and colours in the editor.", bundle: .module)
          .font(.footnote)
          .foregroundStyle(.secondary)
          .multilineTextAlignment(.center)
      }
      .transition(.blurReplace)

    case .failed(let message):
      VStack(spacing: 8) {
        Image(systemName: "exclamationmark.triangle")
          .font(.largeTitle)

        Text(message)
          .font(.footnote)
          .multilineTextAlignment(.center)
          .accessibilityIdentifier("theme.generateError")
      }
      .foregroundStyle(.secondary)
      .transition(.blurReplace)
    }
  }

  // MARK: - Input

  private var descriptionField: some View {
    TextField(
      String(localized: "Describe a theme", bundle: .module),
      text: $viewModel.description,
      axis: .vertical
    )
    .lineLimit(1...3)
    .focused($isDescriptionFocused)
    .submitLabel(.go)
    .onSubmit { viewModel.requestGeneration() }
    .accessibilityIdentifier("theme.description")
    .padding(12)
    .glassEffect(.regular, in: .rect(cornerRadius: 16))
    .disabled(isGenerating)
    // Held to the limit as it is typed, rather than truncated silently on the
    // way to the model.
    .onChange(of: viewModel.description) { _, newValue in
      let limit = TimetableThemeGeneratorViewModel.maximumDescriptionLength
      if newValue.count > limit {
        viewModel.description = String(newValue.prefix(limit))
      }
    }
  }

  private var examplesStrip: some View {
    ScrollView(.horizontal) {
      HStack(spacing: 8) {
        ForEach(Self.examples, id: \.self) { example in
          Button(example) {
            viewModel.description = example
            isDescriptionFocused = false
            viewModel.requestGeneration()
          }
          .buttonStyle(.glass)
          .font(.subheadline)
        }
      }
      .padding(.vertical, 2)
    }
    .scrollIndicators(.hidden)
    .scrollClipDisabled()
    .disabled(isGenerating)
  }

  @ViewBuilder
  private var actions: some View {
    switch viewModel.viewState {
    case .idle, .failed:
      Button {
        isDescriptionFocused = false
        viewModel.requestGeneration()
      } label: {
        actionLabel(String(localized: "Generate", bundle: .module), systemImage: "wand.and.sparkles")
      }
      .buttonStyle(.glassProminent)
      .disabled(!viewModel.canGenerate)
      .accessibilityIdentifier("theme.generate")
      .transition(.blurReplace)

    case .generating:
      Button(action: {}) {
        actionLabel(String(localized: "Generating…", bundle: .module), systemImage: "wand.and.sparkles")
      }
      .buttonStyle(.glassProminent)
      .disabled(true)
      .transition(.blurReplace)

    case .ready:
      HStack(spacing: 8) {
        Button {
          viewModel.requestGeneration()
        } label: {
          Label(String(localized: "Again", bundle: .module), systemImage: "arrow.clockwise")
            .padding(8)
        }
        .buttonStyle(.glass)
        .accessibilityIdentifier("theme.generateAgain")

        Button {
          if let theme = viewModel.previewTheme {
            onApply(theme)
          }
          dismiss()
        } label: {
          actionLabel(String(localized: "Use Theme", bundle: .module), systemImage: "checkmark")
        }
        .buttonStyle(.glassProminent)
        .accessibilityIdentifier("theme.useGenerated")
      }
      .transition(.blurReplace)
    }
  }

  private func actionLabel(_ title: String, systemImage: String) -> some View {
    Label(title, systemImage: systemImage)
      .padding(8)
      .frame(maxWidth: .infinity)
  }

  private var isGenerating: Bool {
    viewModel.viewState == .generating
  }
}

#Preview {
  @Previewable @State var isPresented = true

  NavigationStack { }
    .sheet(isPresented: $isPresented) {
      TimetableThemeGeneratorView(
        baseTheme: TimetableTheme.default.duplicated(named: "My Theme"),
        onApply: { _ in },
        viewModel: TimetableThemeGeneratorViewModel()
      )
    }
}
