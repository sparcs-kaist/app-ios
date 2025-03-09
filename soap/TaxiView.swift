//
//  TaxiView.swift
//  soap
//
//  Created by Soongyu Kwon on 30/10/2024.
//

import SwiftUI

struct TaxiView: View {
  @State private var showsPreviewView = false
  @State private var showsRoomCreationView = false

  var body: some View {
    VStack {
      Button("TaxiPreviewView") {
        showsPreviewView = true
      }

      Button("TaxiRoomCreationView") {
        showsRoomCreationView = true
      }
    }
    .sheet(isPresented: $showsPreviewView) {
      TaxiPreviewView()
        .presentationDetents([.height(600)])
        .presentationDragIndicator(.visible)
    }
    .sheet(isPresented: $showsRoomCreationView) {
      TaxiRoomCreationView()
    }
  }
}

#Preview {
  TaxiView()
}

