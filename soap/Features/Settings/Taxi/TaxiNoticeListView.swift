//
//  TaxiNoticeListView.swift
//  soap
//
//  Created by 하정우 on 8/9/25.
//

import SwiftUI

struct TaxiNoticeListView: View {
  var body: some View {
    List {
      ForEach(0..<5) { id in
        NavigationLink(destination: TaxiNoticeView(id: id)) {
          Text("Notice \(id)")
        }
      }
    }
  }
}

#Preview {
  NavigationStack {
    TaxiNoticeListView()
  }
}
