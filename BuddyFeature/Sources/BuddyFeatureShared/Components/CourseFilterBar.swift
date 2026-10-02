//
//  CourseFilterBar.swift
//  BuddyFeature
//
//  Created by Soongyu Kwon on 30/09/2026.
//

import SwiftUI
import BuddyDomain

/// A row of Liquid Glass filter chips for narrowing a lecture or course search.
///
/// Pass `period` to add the "offered recently" chip, which only course search supports.
public struct CourseFilterBar: View {
  @Binding private var filter: LectureSearchFilter
  private let period: Binding<CourseSearchPeriod?>?
  private let selectedDepartments: [DepartmentOption]
  private let onSelectDepartments: () -> Void

  public init(
    filter: Binding<LectureSearchFilter>,
    period: Binding<CourseSearchPeriod?>? = nil,
    selectedDepartments: [DepartmentOption],
    onSelectDepartments: @escaping () -> Void
  ) {
    self._filter = filter
    self.period = period
    self.selectedDepartments = selectedDepartments
    self.onSelectDepartments = onSelectDepartments
  }

  private var isActive: Bool {
    !filter.isEmpty || period?.wrappedValue != nil
  }

  public var body: some View {
    ScrollView(.horizontal) {
      GlassEffectContainer {
        HStack(spacing: 8) {
          // Part of the row rather than pinned beside it, so it never cuts a chip off.
          if isActive {
            clearButton
              .transition(.scale.combined(with: .opacity))
          }
          departmentChip
          classificationChip
          levelChip
          if let period {
            periodChip(period)
          }
        }
        .padding(.vertical, 4)
      }
    }
    .contentMargins(.horizontal, 16, for: .scrollContent)
    .scrollIndicators(.hidden)
    .animation(.snappy, value: filter)
    .animation(.snappy, value: period?.wrappedValue)
    .sensoryFeedback(.selection, trigger: filter)
    .sensoryFeedback(.selection, trigger: period?.wrappedValue)
  }

  // MARK: - Chips

  private var clearButton: some View {
    Button {
      filter = LectureSearchFilter()
      period?.wrappedValue = nil
    } label: {
      // Not an xmark: a search field next to the bar has its own clear button.
      Image(systemName: "arrow.counterclockwise")
        .font(.subheadline.weight(.semibold))
        .foregroundStyle(.secondary)
        .frame(width: CourseFilterChip.height, height: CourseFilterChip.height)
        .glassEffect(.regular.interactive(), in: .circle)
    }
    .buttonStyle(.plain)
    .accessibilityLabel(String(localized: "Clear Filters", bundle: .module))
  }

  private var departmentChip: some View {
    Button(action: onSelectDepartments) {
      CourseFilterChip(
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
      CourseFilterChip(
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
      CourseFilterChip(
        title: String(localized: "Level", bundle: .module),
        selection: summary(of: LectureSearchFilter.Level.allCases, in: \.levels, by: \.shortTitle)
      )
    }
    .menuOrder(.fixed)
    .buttonStyle(.plain)
  }

  private func periodChip(_ period: Binding<CourseSearchPeriod?>) -> some View {
    Menu {
      Picker(String(localized: "Period", bundle: .module), selection: period) {
        Text("Any Time", bundle: .module).tag(CourseSearchPeriod?.none)
        ForEach(CourseSearchPeriod.allCases) { period in
          Text(period.title).tag(CourseSearchPeriod?.some(period))
        }
      }
    } label: {
      CourseFilterChip(
        title: String(localized: "Period", bundle: .module),
        selection: period.wrappedValue?.title
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
private struct CourseFilterChip: View {
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

private extension CourseSearchPeriod {
  var title: String {
    switch self {
    case .oneYear:
      String(localized: "Within 1 Year", bundle: .module)
    case .twoYears:
      String(localized: "Within 2 Years", bundle: .module)
    case .threeYears:
      String(localized: "Within 3 Years", bundle: .module)
    }
  }
}
