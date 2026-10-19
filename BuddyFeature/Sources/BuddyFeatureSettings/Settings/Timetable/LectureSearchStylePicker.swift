//
//  LectureSearchStylePicker.swift
//  BuddyFeature
//

import SwiftUI
import BuddyDomain

/// Chooses how Add Lecture opens, showing a small phone drawing of each style,
/// like Safari's tab bar setting.
struct LectureSearchStylePicker: View {
  @Binding var selection: LectureSearchStyle

  var body: some View {
    HStack(alignment: .top, spacing: 0) {
      ForEach(LectureSearchStyle.allCases) { style in
        option(style)
          .frame(maxWidth: .infinity)
      }
    }
    .padding(.vertical, 8)
  }

  private func option(_ style: LectureSearchStyle) -> some View {
    let isSelected = style == selection
    return Button {
      withAnimation(.smooth(duration: 0.2)) { selection = style }
    } label: {
      VStack(spacing: 10) {
        LectureSearchStylePreview(style: style, isSelected: isSelected)
        Text(style.title)
          .font(.subheadline)
          .foregroundStyle(.primary)
        Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
          .font(.title2)
          .foregroundStyle(isSelected ? AnyShapeStyle(.tint) : AnyShapeStyle(.tertiary))
          .contentTransition(.symbolEffect(.replace))
      }
      .contentShape(.rect)
    }
    .buttonStyle(.plain)
    .accessibilityElement(children: .ignore)
    .accessibilityLabel(style.title)
    .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
  }
}

/// A phone outline with a sketch of the screen each style produces.
private struct LectureSearchStylePreview: View {
  let style: LectureSearchStyle
  let isSelected: Bool

  private let size = CGSize(width: 54, height: 104)
  // Corners are concentric: each inset shape's radius is the outer radius minus
  // the inset, as on the device itself.
  private let cornerRadius: CGFloat = 13
  private let screenInset: CGFloat = 5
  private var screenRadius: CGFloat { cornerRadius - screenInset }
  private let sheetInset: CGFloat = 2
  private var sheetRadius: CGFloat { screenRadius - sheetInset }

  var body: some View {
    ZStack(alignment: .top) {
      screen
        .clipShape(.rect(cornerRadius: screenRadius))
        .padding(screenInset)

      // Dynamic Island.
      Capsule()
        .frame(width: 14, height: 4)
        .padding(.top, 7)
        .foregroundStyle(stroke)
    }
    .frame(width: size.width, height: size.height)
    .overlay {
      RoundedRectangle(cornerRadius: cornerRadius)
        .strokeBorder(stroke, lineWidth: isSelected ? 2.5 : 2)
    }
    .accessibilityHidden(true)
  }

  private var stroke: AnyShapeStyle {
    isSelected ? AnyShapeStyle(.tint) : AnyShapeStyle(.secondary)
  }

  @ViewBuilder
  private var screen: some View {
    switch style {
    case .sheet: sheetScreen
    case .fullScreen: fullScreen
    }
  }

  /// The timetable stays on top; search results rise in a sheet below it.
  private var sheetScreen: some View {
    VStack(spacing: 0) {
      timetableGrid
        .padding(.top, 12)
        .padding(.horizontal, 3)
      Spacer(minLength: 4)
      VStack(spacing: 3) {
        Capsule().frame(width: 10, height: 2).opacity(0.6)
        searchField
        resultLines(count: 3)
      }
      .padding(.top, 3)
      .padding([.horizontal, .bottom], 3)
      .frame(maxWidth: .infinity, maxHeight: size.height * 0.46, alignment: .top)
      // Floats just inside the screen, like an iOS 26 sheet, with matching corners.
      .background(.quaternary, in: .rect(cornerRadius: sheetRadius))
      .padding([.horizontal, .bottom], sheetInset)
    }
    .foregroundStyle(.secondary)
  }

  /// Search results fill the screen, with a small timetable preview in the
  /// top-right corner, a tap away.
  private var fullScreen: some View {
    VStack(spacing: 3) {
      HStack(alignment: .top, spacing: 3) {
        searchField
          .padding(.top, 3)
        timetableThumbnail
      }
      .padding(.top, 13)
      resultLines(count: 7)
      Spacer(minLength: 0)
    }
    .padding(.horizontal, 4)
    .foregroundStyle(.secondary)
  }

  /// A miniature of the timetable grid, framed like a floating preview.
  private var timetableThumbnail: some View {
    let blocks: [[Bool]] = [[true, false], [false, true]]
    return VStack(spacing: 1.5) {
      ForEach(blocks.indices, id: \.self) { row in
        HStack(spacing: 1.5) {
          ForEach(blocks[row].indices, id: \.self) { column in
            RoundedRectangle(cornerRadius: 1)
              .opacity(blocks[row][column] ? 0.6 : 0.2)
          }
        }
      }
    }
    .padding(2.5)
    .frame(width: 16, height: 15)
    .background(.quaternary, in: .rect(cornerRadius: 3.5))
  }

  private var timetableGrid: some View {
    let blocks: [[Bool]] = [[true, false, true], [false, true, false], [true, true, false]]
    return VStack(spacing: 2) {
      ForEach(blocks.indices, id: \.self) { row in
        HStack(spacing: 2) {
          ForEach(blocks[row].indices, id: \.self) { column in
            RoundedRectangle(cornerRadius: 1.5)
              .frame(height: 7)
              .opacity(blocks[row][column] ? 0.55 : 0.15)
          }
        }
      }
    }
  }

  private var searchField: some View {
    Capsule()
      .frame(height: 5)
      .opacity(0.35)
  }

  private func resultLines(count: Int) -> some View {
    VStack(alignment: .leading, spacing: 3) {
      ForEach(0..<count, id: \.self) { index in
        RoundedRectangle(cornerRadius: 1)
          .frame(width: index.isMultiple(of: 2) ? 30 : 22, height: 3)
          .opacity(0.5)
      }
    }
    .frame(maxWidth: .infinity, alignment: .leading)
  }
}

extension LectureSearchStyle {
  var title: String {
    switch self {
    case .sheet: String(localized: "Sheet", bundle: .module)
    case .fullScreen: String(localized: "Full Screen", bundle: .module)
    }
  }
}

#Preview {
  @Previewable @State var selection = LectureSearchStyle.fullScreen
  List {
    Section {
      LectureSearchStylePicker(selection: $selection)
    }
  }
}
