//
//  SemesterSelector.swift
//  BuddyFeature
//
//  Created by Soongyu Kwon on 8/30/26.
//

import Foundation
import SwiftUI
import BuddyDomain

struct SemesterSelector: View {
  let semesters: [Semester]
  @Binding var selectedSemester: Semester?

  var body: some View {
    ZStack {
      Text(selectedSemester?.description ?? String(localized: "Unknown", bundle: .module))
        .contentTransition(.numericText())
        .animation(.spring, value: selectedSemester?.id)

      // Each half of the selector is a hit target, so tapping anywhere on the
      // left steps back a semester and anywhere on the right steps forward.
      HStack(spacing: 0) {
        halfButton(
          systemImage: "chevron.left",
          alignment: .leading,
          isDisabled: semesters.first == selectedSemester,
          action: {
            BuddyHaptic.decrease.generate()
            selectPreviousSemester()
          }
        )

        halfButton(
          systemImage: "chevron.right",
          alignment: .trailing,
          isDisabled: semesters.last == selectedSemester,
          action: {
            BuddyHaptic.increase.generate()
            selectNextSemester()
          }
        )
      }
    }
    .frame(maxWidth: 160)
    .fontWeight(.semibold)
    .padding(12)
    .padding(.horizontal, 4)
    .glassEffect(.regular.interactive())
  }

  private func halfButton(
    systemImage: String,
    alignment: Alignment,
    isDisabled: Bool,
    action: @escaping () -> Void
  ) -> some View {
    Button(action: action, label: {
      Image(systemName: systemImage)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: alignment)
        .contentShape(.rect)
    })
    .buttonStyle(.plain)
    .disabled(isDisabled)
    .unredacted()
  }

  private func selectPreviousSemester() {
    guard
      let selectedSemester,
      let currentIndex = semesters.firstIndex(of: selectedSemester),
      currentIndex > 0
    else { return }

    withAnimation(.spring) {
      self.selectedSemester = semesters[currentIndex - 1]
    }
  }

  private func selectNextSemester() {
    guard
      let selectedSemester,
      let currentIndex = semesters.firstIndex(of: selectedSemester),
      currentIndex < semesters.count - 1
    else { return }

    withAnimation(.spring) {
      self.selectedSemester = semesters[currentIndex + 1]
    }
  }
}
