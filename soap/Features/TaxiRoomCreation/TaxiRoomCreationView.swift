//
//  TaxiRoomCreationView.swift
//  soap
//
//  Created by Soongyu Kwon on 09/03/2025.
//

import SwiftUI

struct TaxiRoomCreationView: View {
  @State private var viewModel = TaxiRoomCreationViewModel()
  
  var body: some View {
    NavigationView {
      VStack {
        // TODO: Destination
        
        Form {
          Section {
            TextField("Title", text: $viewModel.roomName)
          }
          
          Section {
            TaxiDepatureTimePicker(depatureTime: $viewModel.roomDepatureTime)
            Picker("Capacity", selection: $viewModel.roomCapacity) {
              ForEach(2...4, id: \.self) { number in
                Label {
                  Text("\(number) People")
                } icon: {
                  Image(systemName: "person.\(number).fill")
                }
                .tag(number)
              }
            }
          }
        }
      }
      .navigationTitle("Create")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .navigationBarTrailing) {
          Button("Done") {
            // TODO: dismiss
          }
        }
      }
    }
  }
}

#Preview {
  TaxiRoomCreationView()
}
