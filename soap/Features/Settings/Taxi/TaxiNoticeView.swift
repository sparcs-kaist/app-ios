//
//  TaxiNoticeView.swift
//  soap
//
//  Created by 하정우 on 8/9/25.
//

import SwiftUI

struct TaxiNoticeView: View {
  var id: Int
  
  var body: some View {
    Text("Notice \(id) Detail")
  }
}

#Preview {
  TaxiNoticeView(id: 0)
}
