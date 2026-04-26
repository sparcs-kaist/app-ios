//
//  RowElementView.swift
//  soap
//
//  Created by 하정우 on 8/8/25.
//

import SwiftUI

struct RowElementView: View {
  var title: String.LocalizationValue
  var content: String.LocalizationValue
  
  var body: some View {
    HStack {
      Text(title, bundle: .module)
      Spacer()
      Text(content, bundle: .module)
        .foregroundStyle(.secondary)
    }
  }
}

#Preview {
  List {
    RowElementView(title: "Title", content: "Content")
  }
}
