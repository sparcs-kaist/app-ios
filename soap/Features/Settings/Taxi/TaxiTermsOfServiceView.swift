//
//  TaxiTermsOfServiceView.swift
//  soap
//
//  Created by 하정우 on 8/9/25.
//

import SwiftUI

struct TaxiTermsOfServiceView: View {
  @State var isAgreed: Bool = false
  
  var body: some View {
    VStack {
      ScrollableTextView("taxi_terms_of_service")
      HStack {
        Spacer()
        Button("Agree") { }
        .disabled(isAgreed)
      }
    }.padding(.horizontal)
  }
}

#Preview {
  NavigationStack {
    TaxiTermsOfServiceView()
      .navigationTitle("Taxi Terms of Service")
      .navigationBarTitleDisplayMode(.inline)
  }
}
