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

      Button(action: {
        viewModel.signIn()
      }, label: {
        Group {
          if viewModel.isLoading {
            ProgressView()
              .tint(.white)
          } else {
            Text("Sign In with SPARCS SSO")
              .fontWeight(.medium)
          }
        }
        .frame(maxWidth: .infinity)
        .padding(8)
      })
      .buttonStyle(.glassProminent)
      .disabled(viewModel.isLoading)
    }
    .padding()
  }
}


#Preview {
  SignInView()
}
