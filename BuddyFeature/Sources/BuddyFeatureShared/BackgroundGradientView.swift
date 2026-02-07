//
//  BackgroundGradientView.swift
//  soap
//
//  Created by Soongyu Kwon on 07/10/2025.
//

import SwiftUI

public struct BackgroundGradientView: View {
  let color: Color

  @Environment(\.colorScheme) private var colorScheme

  public init(color: Color) {
    self.color = color
  }

  public var body: some View {
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
