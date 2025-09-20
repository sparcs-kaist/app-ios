//
//  LectureSearchView.swift
//  soap
//
//  Created by Soongyu Kwon on 20/09/2025.
//

import SwiftUI

struct LectureSearchView: View {
  @State private var searchText: String = ""
  @State private var isFiltered: Bool = false

  var body: some View {
    NavigationStack {
      List {
        Text("test")
      }
      .navigationBarTitleDisplayMode(.inline)
      .searchable(text: $searchText, prompt: Text("Search courses, codes or professors"))
    }
  }
}

#Preview {
  @Previewable @State var showSheet: Bool = true
  ZStack {
    Button("test") {
      showSheet = true
    }
  }
  .sheet(isPresented: $showSheet) {
    LectureSearchView()
      .presentationDetents([.medium, .large, .height(100)])
  }
}


