//
//  MapDiscoveryView.swift
//  BuddyFeature
//
//  Created by Soongyu Kwon on 14/03/2026.
//

import SwiftUI

public struct MapDiscoveryView: View {
  @State private var showMap: Bool = false

  public init() { }

  public var body: some View {
    Button("hit") {
      showMap = true
    }
    .fullScreenCover(isPresented: $showMap) {
      MapView()
    }
  }
}


#Preview {
  MapDiscoveryView()
}
