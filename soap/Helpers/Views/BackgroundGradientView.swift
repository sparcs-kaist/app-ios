//
//  BackgroundGradientView.swift
//  soap
//
//  Created by Soongyu Kwon on 07/10/2025.
//

import SwiftUI

struct BackgroundGradientView: View {
  let color: Color

  @Environment(\.colorScheme) private var colorScheme

  var body: some View {
    Group {
      if colorScheme == .dark {
        LinearGradient(
          gradient: Gradient(colors: [
            color.opacity(0.2),
            color.opacity(0.05),
            .clear
          ]),
          startPoint: .top,
          endPoint: .bottom
        )
      }
    }
  }
}
