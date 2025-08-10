//
//  TaxiReportView.swift
//  soap
//
//  Created by 김민찬 on 8/11/25.
//

import SwiftUI
import NukeUI

struct TaxiReportView: View {
  var participants: [TaxiParticipant]
  
  @State private var viewModel = TaxiReportViewModel()
  @Environment(\.dismiss) private var dismiss
  
  var body: some View {
    NavigationView {
      Form {
        Section("Who?") {
          Picker("Select", selection: $viewModel.selectedUser) {
            ForEach(participants) { part in
              TaxiReportUser(user: part).tag(part)
            }
          }
          .pickerStyle(.inline)
          .labelsHidden()
        }
        
        Section("Why?") {
          Picker("Reason", selection: $viewModel.selectedReason) {
            Text("Select")
              .foregroundStyle(.secondary)
              .tag(TaxiReport.Reason?.none)
              .selectionDisabled()
            
            Text("Didn't send money!").tag(TaxiReport.Reason.noSettlement)
            Text("Didn't come on time!").tag(TaxiReport.Reason.noShow)
            Text("Etc").tag(TaxiReport.Reason.etcReason)
          }
          
          if viewModel.selectedReason == .etcReason {
            TextField("Details", text: $viewModel.etcReasonDetail)
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
            // TODO
          }
          .disabled(!isValid)
        }
      }
    }
  }
  
  var isValid: Bool {
    return (
      viewModel.selectedUser != nil && viewModel.selectedReason != nil &&
      (viewModel.selectedReason != .etcReason || !viewModel.etcReasonDetail.isEmpty)
    )
  }
}

#Preview {
  TaxiReportView(participants: TaxiRoom.mock.participants)
}
