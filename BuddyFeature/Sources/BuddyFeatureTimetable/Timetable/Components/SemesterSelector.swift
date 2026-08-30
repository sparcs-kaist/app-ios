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
    HStack {
      Button(action: {
        BuddyHaptic.decrease.generate()
        selectPreviousSemester()
      }, label: {
        Image(systemName: "chevron.left")
      })
      .tint(.primary)
      .disabled(semesters.first == selectedSemester)
      .unredacted()

      Spacer()

      Text(selectedSemester?.description ?? String(localized: "Unknown", bundle: .module))
        .contentTransition(.numericText())
        .animation(.spring, value: selectedSemester?.id)

      Spacer()

      Button(action: {
        BuddyHaptic.increase.generate()
        selectNextSemester()
      }, label: {
        Image(systemName: "chevron.right")
      })
      .tint(.primary)
      .disabled(semesters.last == selectedSemester)
      .unredacted()
    }
    .frame(maxWidth: 160)
    .fontWeight(.semibold)
    .padding(12)
    .padding(.horizontal, 4)
    .glassEffect(.regular.interactive())
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
