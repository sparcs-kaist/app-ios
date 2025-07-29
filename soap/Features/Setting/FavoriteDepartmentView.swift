//
//  FavoriteDepartmentView.swift
//  soap
//
//  Created by 하정우 on 7/29/25.
//

import SwiftUI

struct FavoriteDepartmentView: View {
  var majors: [String] = ["School of Computer Science", "School of Electrical Engineering", "School of Business"]
  
  @State private var selectedMajor: Int
  
  init(selectedMajor: Int) {
    self.selectedMajor = selectedMajor
  }
  
  var body: some View {
    NavigationView {
      List {
        Picker(selection: $selectedMajor, label: EmptyView()) {
          ForEach(0..<majors.count, id: \.self) {
            Text(majors[$0])
          }
        }
        .pickerStyle(.inline)
      }
    }
    .navigationTitle(Text("Major"))
  }
}

#Preview {
  // TODO: remove weird padding on the top of the preview
  NavigationStack {
    FavoriteDepartmentView(selectedMajor: 1)
    .navigationBarTitleDisplayMode(.inline)
  }
}
