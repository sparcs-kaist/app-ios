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

  /// Starting points, not presets: tapping one fills the field and sends it,
  /// and it can be edited and sent again.
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
          status
        }
        .contentWidth()
      }
      .scrollDismissesKeyboard(.interactively)
      .contentMargins(.horizontal, 16, for: .scrollContent)
      .contentMargins(.vertical, 12, for: .scrollContent)
      .animation(.smooth, value: viewModel.viewState)
      .animation(.smooth, value: viewModel.previewTheme)
      .navigationBarTitleDisplayMode(.inline)
      .navigationTitle(Text("Generate Theme", bundle: .module))
      .safeAreaBar(edge: .bottom) {
        inputBar
      }
      .toolbar {
        ToolbarItem(placement: .cancellationAction) {
          Button("Close", systemImage: "xmark", role: .close) {
            dismiss()
          }
        }

        // Keeping the theme is the sheet's one confirmation, so it belongs
        // here rather than competing with the field for the bottom of the
        // screen.
        ToolbarItem(placement: .confirmationAction) {
          Button(role: .confirm) {
            if let theme = viewModel.previewTheme {
              onApply(theme)
            }
            dismiss()
          }
          .disabled(viewModel.viewState != .ready)
          .accessibilityIdentifier("theme.useGenerated")
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

  /// The same shape as writing a comment: a field, and a button that arrives
  /// beside it once there is something to send. Sending is also what asks
  /// again, so a second opinion is the same gesture as the first rather than
  /// another button to find.
  private var inputBar: some View {
    VStack(spacing: 8) {
      if viewModel.description.isEmpty {
        examplesStrip
          .transition(.move(edge: .bottom).combined(with: .opacity))
      }

      HStack(alignment: .bottom) {
        TextField(
          String(localized: "Describe a theme", bundle: .module),
          text: $viewModel.description
        )
        .focused($isDescriptionFocused)
        .submitLabel(.send)
        .onSubmit(send)
        .accessibilityIdentifier("theme.description")
        .padding(12)
        .glassEffect(.regular.interactive(), in: .rect(cornerRadius: 24))
        .tint(.primary)
        // Held to the limit as it is typed, rather than truncated silently on
        // the way to the model.
        .onChange(of: viewModel.description) { _, newValue in
          let limit = TimetableThemeGeneratorViewModel.maximumDescriptionLength
          if newValue.count > limit {
            viewModel.description = String(newValue.prefix(limit))
          }
        }

        if viewModel.canGenerate {
          Button(action: send) {
            if isGenerating {
              ProgressView()
                .tint(.white)
                .accessibilityLabel(Text("Generating…", bundle: .module))
            } else {
              Label(String(localized: "Generate", bundle: .module), systemImage: "wand.and.sparkles")
                .labelStyle(.iconOnly)
                .tint(.white)
            }
          }
          .fontWeight(.medium)
          .padding(12)
          .glassEffect(.regular.tint(Color.accentColor).interactive(), in: .circle)
          .disabled(isGenerating)
          .accessibilityIdentifier("theme.generate")
          .transition(.move(edge: .trailing).combined(with: .opacity))
        }
      }
    }
    .padding(.horizontal)
    .contentWidth()
    .animation(
      .spring(duration: 0.35, bounce: 0.4, blendDuration: 0.15),
      value: viewModel.canGenerate
    )
  }

  private var examplesStrip: some View {
    ScrollView(.horizontal) {
      HStack(spacing: 8) {
        ForEach(Self.examples, id: \.self) { example in
          Button(example) {
            viewModel.description = example
            send()
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

  private func send() {
    isDescriptionFocused = false
    viewModel.requestGeneration()
  }

  private var isGenerating: Bool {
    viewModel.viewState == .generating
  }
}

/// Rendered directly rather than through `sheet`, which the canvas only ever
/// catches halfway through presenting.
#Preview {
  TimetableThemeGeneratorView(
    baseTheme: TimetableTheme.default.duplicated(named: "My Theme"),
    onApply: { _ in },
    viewModel: TimetableThemeGeneratorViewModel()
  )
}

#Preview("Described") {
  let viewModel = TimetableThemeGeneratorViewModel()
  viewModel.description = "Cosy autumn café"

  return TimetableThemeGeneratorView(
    baseTheme: TimetableTheme.default.duplicated(named: "My Theme"),
    onApply: { _ in },
    viewModel: viewModel
  )
}
