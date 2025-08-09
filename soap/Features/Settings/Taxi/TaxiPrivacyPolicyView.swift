//
//  TaxiSettingsPrivacyPolicyView.swift
//  soap
//
//  Created by 하정우 on 8/9/25.
//

import SwiftUI

struct TaxiPrivacyPolicyView: View {
  var body: some View {
    ScrollableTextView("Taxi Privacy Policy").padding(.horizontal)
  }
}

#Preview {
  NavigationStack {
    TaxiPrivacyPolicyView()
      .navigationTitle(Text("Taxi Privacy Policy"))
      .navigationBarTitleDisplayMode(.inline)
  }
}
