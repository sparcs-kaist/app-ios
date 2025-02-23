//
//  Checkbox.swift
//  soap
//
//  Created by Soongyu Kwon on 15/02/2025.
//

import SwiftUI

struct Checkbox: View {
  let title: String
  @Binding var isChecked: Bool

  @State private var isPressed: Bool = false

  init(_ title: String, isChecked: Binding<Bool>) {
    self.title = title
    self._isChecked = isChecked
  }

  var body: some View {
    Group {
      HStack {
        ZStack {
          RoundedRectangle(cornerRadius: 4)
            .frame(width: 20, height: 20)

          Image(systemName: "checkmark")
            .font(.subheadline)
            .fontWeight(.bold)
            .blendMode(.destinationOut)
        }
        .compositingGroup()
        .onTapGesture {
          isChecked.toggle() // Toggle checkbox state
        }

        Text(title)
      }
      .opacity(isChecked ? 1 : 0.22)
      .scaleEffect(isPressed ? 0.98 : 1)
    }
    .onTapGesture {
      withAnimation(.spring(duration: 0.2)) {
        isChecked.toggle()
      }
    }
    .simultaneousGesture(
      DragGesture(minimumDistance: 0)
        .onChanged { _ in
          withAnimation(.spring(duration: 0.2)) {
            isPressed = true
          }
        }
        .onEnded { _ in
          withAnimation(.spring(duration: 0.2)) {
            isPressed = false
          }
        }
    )
  }
}

#Preview {
  Checkbox("Sample", isChecked: .constant(true))
  Checkbox("Sample", isChecked: .constant(false))
}
