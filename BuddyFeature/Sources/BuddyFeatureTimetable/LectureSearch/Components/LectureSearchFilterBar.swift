//
//  LectureSearchFilterBar.swift
//  BuddyFeature
//
//  Created by Soongyu Kwon on 30/09/2026.
//

import SwiftUI
import BuddyDomain

/// The row of filter chips that sits directly above the search field.
struct LectureSearchFilterBar: View {
  @Binding var filter: LectureSearchFilter
  let selectedDepartments: [DepartmentOption]
  let onSelectDepartments: () -> Void

  var body: some View {
    HStack(spacing: 8) {
      ScrollView(.horizontal) {
        GlassEffectContainer {
          HStack(spacing: 8) {
            departmentChip
            classificationChip
            levelChip
          }
          .padding(.vertical, 4)
        }
      }
      .contentMargins(.horizontal, 16, for: .scrollContent)
      .scrollIndicators(.hidden)

      // Pinned beside the chips so it stays reachable and never shifts them around.
      if !filter.isEmpty {
        clearButton
          .padding(.trailing)
          .transition(.scale.combined(with: .opacity))
      }
    }
    .animation(.snappy, value: filter)
    .sensoryFeedback(.selection, trigger: filter)
  }

  // MARK: - Chips

  private var clearButton: some View {
    Button {
      filter = LectureSearchFilter()
    } label: {
      // Not an xmark: the search field right below has its own clear button.
      Image(systemName: "arrow.counterclockwise")
        .font(.subheadline.weight(.semibold))
        .foregroundStyle(.secondary)
        .frame(width: LectureSearchFilterChip.height, height: LectureSearchFilterChip.height)
        .glassEffect(.regular.interactive(), in: .circle)
    }
    .buttonStyle(.plain)
    .accessibilityLabel(String(localized: "Clear Filters", bundle: .module))
  }

  private var departmentChip: some View {
    Button(action: onSelectDepartments) {
      LectureSearchFilterChip(
        title: String(localized: "Department", bundle: .module),
        selection: departmentSummary
      )
    }
    .buttonStyle(.plain)
  }

  private var classificationChip: some View {
    Menu {
      ForEach(LectureSearchFilter.Classification.allCases) { classification in
        Toggle(classification.displayName.localized(), isOn: binding(for: classification, in: \.classifications))
      }
      .menuActionDismissBehavior(.disabled)
    } label: {
      LectureSearchFilterChip(
        title: String(localized: "Type", bundle: .module),
        selection: summary(of: LectureSearchFilter.Classification.allCases, in: \.classifications, by: \.shortCode)
      )
    }
    .menuOrder(.fixed)
    .buttonStyle(.plain)
  }

  private var levelChip: some View {
    Menu {
      ForEach(LectureSearchFilter.Level.allCases) { level in
        Toggle(level.title, isOn: binding(for: level, in: \.levels))
      }
      .menuActionDismissBehavior(.disabled)
    } label: {
      LectureSearchFilterChip(
        title: String(localized: "Level", bundle: .module),
        selection: summary(of: LectureSearchFilter.Level.allCases, in: \.levels, by: \.shortTitle)
      )
    }
    .menuOrder(.fixed)
    .buttonStyle(.plain)
  }

  // MARK: - Helpers

  /// Codes keep the chip compact however long the department names are.
  private var departmentSummary: String? {
    selectedDepartments.isEmpty ? nil : selectedDepartments.map(\.code).joined(separator: ", ")
  }

  private func summary<Option: Hashable>(
    of options: [Option],
    in keyPath: KeyPath<LectureSearchFilter, Set<Option>>,
    by label: (Option) -> String
  ) -> String? {
    let selected = options.filter(filter[keyPath: keyPath].contains)
    return selected.isEmpty ? nil : selected.map(label).joined(separator: ", ")
  }

  private func binding<Option: Hashable>(
    for option: Option,
    in keyPath: WritableKeyPath<LectureSearchFilter, Set<Option>>
  ) -> Binding<Bool> {
    Binding(
      get: { filter[keyPath: keyPath].contains(option) },
      set: { isOn in
        if isOn {
          filter[keyPath: keyPath].insert(option)
        } else {
          filter[keyPath: keyPath].remove(option)
        }
      }
    )
  }
}

/// A Liquid Glass capsule that shows a filter's name, or what is selected once it is in use.
private struct LectureSearchFilterChip: View {
  /// Matches the system's glass toolbar controls, which is also the minimum touch target.
  static let height: CGFloat = 44
  private static let maximumTitleWidth: CGFloat = 200

  let title: String
  let selection: String?

  private var isActive: Bool { selection != nil }

  var body: some View {
    HStack(spacing: 5) {
      Text(selection ?? title)
        .lineLimit(1)
        .frame(maxWidth: Self.maximumTitleWidth)
        .fixedSize()

      Image(systemName: "chevron.down")
        .font(.caption2.weight(.bold))
        .opacity(0.6)
    }
    .font(.subheadline.weight(.medium))
    .foregroundStyle(isActive ? AnyShapeStyle(.white) : AnyShapeStyle(.primary))
    .padding(.horizontal, 16)
    .frame(height: Self.height)
    .glassEffect(.regular.tint(isActive ? Color.accentColor : nil).interactive(), in: .capsule)
    .accessibilityElement(children: .ignore)
    .accessibilityLabel(title)
    .accessibilityValue(selection ?? "")
  }
}

private extension LectureSearchFilter.Level {
  var title: String {
    switch self {
    case .graduate:
      String(localized: "500 and Above", bundle: .module)
    default:
      String(localized: "\(rawValue) Level", bundle: .module)
    }
  }

  var shortTitle: String {
    switch self {
    case .graduate:
      "500+"
    default:
      String(rawValue)
    }
  }
}
