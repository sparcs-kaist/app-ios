//
//  TaxiReportView.swift
//  soap
//
//  Created by 김민찬 on 8/11/25.
//

import SwiftUI
import NukeUI

struct TaxiReportView: View {
  var room: TaxiRoom
  
  @State private var viewModel = TaxiReportViewModel()
  @Environment(\.dismiss) private var dismiss
  
  var body: some View {
    NavigationView {
      Form {
        Section("Who?") {
          Picker("Select", selection: $viewModel.selectedUser) {
            ForEach(room.participants) { part in
              TaxiReportUser(user: part).tag(part) // TODO: Exclude myself
            }
          }
          .pickerStyle(.inline)
          .labelsHidden()
        }
        
        Section {
          Picker("Reason", selection: $viewModel.selectedReason) {
            Text("Select")
              .tag(TaxiReport.Reason?.none)
              .selectionDisabled()
            Text("Didn't send money!")
              .tag(TaxiReport.Reason.noSettlement)
              .selectionDisabled(!room.isDeparted)
            Text("Didn't come on time!")
              .tag(TaxiReport.Reason.noShow)
              .selectionDisabled(!room.isDeparted)
            Text("Etc").tag(TaxiReport.Reason.etcReason)
          }
          
          if viewModel.selectedReason == .etcReason {
            HStack {
              TextField("Details", text: $viewModel.etcDetails)
              Text("\(viewModel.etcDetails.count)/30")
                .foregroundStyle(viewModel.etcDetails.count > 30 ? .orange : .secondary)
            }
          }
        } header: {
          Text("Why?")
        } footer: {
          VStack(alignment: .leading, spacing: 8) {
            if !room.isDeparted {
              Text("Reports for unsettled payments and no-shows can only be submitted after the departure time.")
            }
            if viewModel.selectedReason == .noSettlement {
              Text("An email will be sent asking them to send you the money.")
            }
          }
        }
      }
      .navigationTitle("Report")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .topBarLeading) {
          Button("Cancel", systemImage: "xmark", role: .close) {
            dismiss()
          }
        }
        
        ToolbarItem(placement: .topBarTrailing) {
          Button("Done", systemImage: "arrow.up", role: .confirm) {
            Task {
              do {
                try await viewModel.createReport(roomID: room.id)
                dismiss()
              } catch {
                // TODO: Error Handling
              }
            }
          }
          .disabled(!isValid)
        }
      }
    }
  }
  
  var isValid: Bool {
    return (
      viewModel.selectedUser != nil && viewModel.selectedReason != nil &&
      (viewModel.selectedReason != .etcReason || (1...30).contains(viewModel.etcDetails.count))
    )
  }
}

#Preview {
  TaxiReportView(room: TaxiRoom.mock)
}
