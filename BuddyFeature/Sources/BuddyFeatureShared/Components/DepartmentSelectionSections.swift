//
//  DepartmentSelectionSections.swift
//  BuddyFeature
//
//  Created by Soongyu Kwon on 30/09/2026.
//

import SwiftUI
import BuddyDomain

/// The sections of a multi-select department list, for use inside a `List`.
///
/// The user's interested departments come first; everything else keeps the order it was given
/// in, which for the OTL API already puts the undergraduate departments at the top.
public struct DepartmentSelectionSections: View {
  private let departments: [DepartmentOption]
  private let interestedDepartmentIDs: Set<Int>
  private let searchText: String
  @Binding private var selection: Set<Int>

  public init(
    departments: [DepartmentOption],
    interestedDepartmentIDs: Set<Int>,
    searchText: String,
    selection: Binding<Set<Int>>
  ) {
    self.departments = departments
    self.interestedDepartmentIDs = interestedDepartmentIDs
    self.searchText = searchText
    self._selection = selection
  }

  public var body: some View {
    let keyword = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
    let interested = departments.filter { interestedDepartmentIDs.contains($0.id) }

    if !keyword.isEmpty {
      let matches = matches(for: keyword)
      if matches.isEmpty {
        ContentUnavailableView.search(text: searchText)
      } else {
        Section {
          rows(matches)
        }
      }
    } else if interested.isEmpty {
      Section {
        rows(departments)
      }
    } else {
      Section(String(localized: "Interested Departments", bundle: .module)) {
        rows(interested)
      }
      Section(String(localized: "Other Departments", bundle: .module)) {
        rows(departments.filter { !interestedDepartmentIDs.contains($0.id) })
      }
    }
  }

  private func matches(for keyword: String) -> [DepartmentOption] {
    let matches = departments.filter {
      $0.name.localizedCaseInsensitiveContains(keyword) || $0.code.localizedCaseInsensitiveContains(keyword)
    }
    // Typing a code such as "CS" should surface that department ahead of looser name matches.
    let isCodeMatch: (DepartmentOption) -> Bool = {
      $0.code.localizedCaseInsensitiveCompare(keyword) == .orderedSame
    }
    return matches.filter(isCodeMatch) + matches.filter { !isCodeMatch($0) }
  }

  private func rows(_ departments: [DepartmentOption]) -> some View {
    ForEach(departments) { department in
      let isSelected = selection.contains(department.id)

      Button {
        if isSelected {
          selection.remove(department.id)
        } else {
          selection.insert(department.id)
        }
      } label: {
        HStack {
          VStack(alignment: .leading, spacing: 2) {
            Text(department.name)
              .foregroundStyle(.primary)
            Text(department.code)
              .font(.footnote)
              .foregroundStyle(.secondary)
          }

          Spacer()

          Image(systemName: "checkmark")
            .fontWeight(.semibold)
            .foregroundStyle(.tint)
            .opacity(isSelected ? 1 : 0)
        }
        .contentShape(.rect)
      }
      .buttonStyle(.plain)
      .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
  }
}
