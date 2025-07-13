//
//  RouteHeaderView.swift
//  soap
//
//  Created by Minjae Kim on 5/4/25.
//

import SwiftUI

struct RouteHeaderView: View {
  let origin: String
  let destination: String

  var body: some View {
    VStack(alignment: .leading, spacing: 8) {
      Label(origin, systemImage: "location.fill")
      Label(destination, systemImage: "flag.pattern.checkered")
    }
    .font(.title3)
    .fontWeight(.semibold)
    .frame(maxWidth: .infinity, alignment: .leading)
  }
}

#Preview {
  RouteHeaderView(origin: "Seoul", destination: "Busan")
    .padding()
}

