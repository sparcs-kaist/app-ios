//
//  View+Extensions.swift
//  soap
//
//  Created by Soongyu Kwon on 20/08/2025.
//

import SwiftUI

// MARK: - Width reader (no GeometryReader height bugs)
struct WidthKey: PreferenceKey {
  static let defaultValue: CGFloat = 0
  static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) { value = nextValue() }
}

extension View {
  func measureWidth(_ onChange: @escaping (CGFloat) -> Void) -> some View {
    background(
      GeometryReader { proxy in
        Color.clear.preference(key: WidthKey.self, value: proxy.size.width)
      }
    )
    .onPreferenceChange(WidthKey.self, perform: onChange)
  }
  
  func windowSizeClass(_ sizeClass: UserInterfaceSizeClass?) -> some View {
    environment(\.windowSizeClass, sizeClass)
  }
}
