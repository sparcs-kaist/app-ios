//
//  TentativeBlock.swift
//  BuddyUI
//
//  Created by Soongyu Kwon on 02/10/2026.
//

import SwiftUI

/// How a lecture that is only being previewed is drawn: a tint of the colour it would have once
/// added, with diagonal stripes and a dashed outline, as calendars draw tentative events.
struct TentativeBlock: View {
  let color: Color
  var cornerRadius: CGFloat = 4
  var lineWidth: CGFloat = 1.5
  var dash: [CGFloat] = [4, 3]
  /// Too fine to read on small blocks, such as a silhouette's.
  var showsStripes = true

  var body: some View {
    let shape = RoundedRectangle(cornerRadius: cornerRadius)
    shape
      .fill(color.opacity(0.2))
      .overlay {
        if showsStripes {
          DiagonalStripes(spacing: 7)
            .stroke(color.opacity(0.3), lineWidth: 2)
            .clipShape(shape)
        }
      }
      .overlay {
        shape.strokeBorder(color, style: StrokeStyle(lineWidth: lineWidth, dash: dash))
      }
  }
}

/// Parallel lines rising from bottom left to top right, `spacing` apart.
private struct DiagonalStripes: Shape {
  let spacing: CGFloat

  func path(in rect: CGRect) -> Path {
    var path = Path()
    var x = -rect.height
    while x < rect.width {
      path.move(to: CGPoint(x: rect.minX + x, y: rect.maxY))
      path.addLine(to: CGPoint(x: rect.minX + x + rect.height, y: rect.minY))
      x += spacing
    }
    return path
  }
}

#Preview("Tentative", traits: .fixedLayout(width: 88, height: 105)) {
  TentativeBlock(color: .pink)
    .padding()
}
