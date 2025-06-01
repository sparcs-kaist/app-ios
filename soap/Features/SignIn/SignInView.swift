//
//  SignInView.swift
//  soap
//
//  Created by Soongyu Kwon on 30/05/2025.
//

import SwiftUI

struct SignInView: View {
  @State private var viewModel = SignInViewModel()

  var body: some View {
    VStack {
      Spacer()
      Text("SPARCS APP INTERNAL")
      Spacer()

      Button("Sign In with SPARCS") {
        viewModel.signIn()
      }
    }
    .padding()
  }
}


#Preview {
  SignInView()
}
