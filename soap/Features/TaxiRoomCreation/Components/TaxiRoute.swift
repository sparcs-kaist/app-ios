//
//  TaxiRoute.swift
//  soap
//
//  Created by 김민찬 on 3/23/25.
//

import SwiftUI

struct TaxiRoute: View {
  var body: some View {
    HStack {
      VStack(alignment: .leading) {
        Button(action: {
          // TODO
        }) {
          Image(systemName: "flag")
          Text("Hi")
        }
        .buttonStyle(PlainButtonStyle())
        Button(action: {
          // TODO
        }) {
          Image(systemName: "flag")
          Text("Hi2")
        }
        .buttonStyle(PlainButtonStyle())
      }
      Spacer()
      Image(systemName: "arrow.up.arrow.down")
    }
    .padding() // TODO: FIXME
    .background(Color(.systemGray6)) // TODO: FIXME
    .cornerRadius(8) // TODO: FIXME
  }
}

#Preview {
  TaxiRoute()
}
