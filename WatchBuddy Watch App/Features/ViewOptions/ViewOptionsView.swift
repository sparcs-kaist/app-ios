//
//  ViewOptionsView.swift
//  WatchBuddy Watch App
//
//  Created by Soongyu Kwon on 24/09/2026.
//

import SwiftUI

struct ViewOptionsView: View {
  let selection: LectureViewOption
  let onSelect: (LectureViewOption) -> Void

  var body: some View {
    NavigationStack {
      List(LectureViewOption.allCases) { option in
        Button {
          onSelect(option)
        } label: {
          HStack {
            Label(option.title, systemImage: option.systemImage)
            Spacer()
            if option == selection {
              Image(systemName: "checkmark")
                .foregroundStyle(.tint)
            }
          }
        }
      }
      .navigationTitle("View Options")
    }
  }
}

#Preview {
  ViewOptionsView(selection: .upNext) { _ in }
}
