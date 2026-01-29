//
//  RowElementView.swift
//  soap
//
//  Created by 하정우 on 8/8/25.
//

import SwiftUI

struct RowElementView: View {
  var title: String
  var content: String
  
  var body: some View {
    HStack {
      Text(title)
      Spacer()
      Text(content)
        .foregroundStyle(.secondary)
    }
  }
}

#Preview {
  List {
    RowElementView(title: "Title", content: "Content")
  }
}
