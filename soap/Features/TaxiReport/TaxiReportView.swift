//
//  TaxiReportView.swift
//  soap
//
//  Created by 김민찬 on 8/11/25.
//

import SwiftUI
import NukeUI
import Factory
import BuddyDomain

struct TaxiReportView: View {
  var room: TaxiRoom
  
  @State private var viewModel = TaxiReportViewModel()
  @State private var taxiUser: TaxiUser? = nil
  @State private var isUploading: Bool = false
  @Environment(\.dismiss) private var dismiss
  
  @State private var presentAlert: Bool = false
  @State private var alertTitle: String = ""
  @State private var alertContent: String = ""
  
  // MARK: - Dependencies
  @Injected(\.userUseCase) private var userUseCase: UserUseCaseProtocol
  
  var body: some View {
    NavigationStack {
      Form {
        Section("Who?") {
          Picker("Select", selection: $viewModel.selectedUser) {
            ForEach(room.participants.filter { $0.id != taxiUser?.oid }) { part in
              TaxiReportUser(user: part).tag(part)
            }
          }
          .pickerStyle(.inline)
          .labelsHidden()
        }
        .task {
          self.taxiUser = await userUseCase.taxiUser
        }
        
        Section {
          Picker("Reason", selection: $viewModel.selectedReason) {
            Text("Select")
              .tag(TaxiReport.Reason?.none)
              .selectionDisabled()
            Text("Didn't send money")
              .tag(TaxiReport.Reason.noSettlement)
              .selectionDisabled(!room.isDeparted)
            Text("Didn't come on time")
              .tag(TaxiReport.Reason.noShow)
              .selectionDisabled(!room.isDeparted)
            Text("ETC").tag(TaxiReport.Reason.etcReason)
          }
          
          if viewModel.selectedReason == .etcReason {
            HStack {
              TextField("Details", text: $viewModel.etcDetails)
              Text("\(viewModel.etcDetails.count)/\(viewModel.maxEtcDetailsLength)")
                .foregroundStyle(viewModel.etcDetails.count > viewModel.maxEtcDetailsLength ? .orange : .secondary)
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
        ToolbarItem(placement: .topBarTrailing) {
          Button(
            role: .confirm,
            action: {
              Task {
                do {
                  isUploading = true
                  defer { isUploading = false }
                  try await viewModel.createReport(roomID: room.id)
                  dismiss()
                } catch {
                  if error.isNetworkMoyaError {
                    showAlert(title: String(localized: "Error"), content: String(localized: "You are not connected to the Internet."))
                  } else {
                    viewModel.handleException(error)
                    showAlert(title: String(localized: "Error"), content: String(localized: "An unexpected error occurred while reporting a user. Please try again later."))
                  }
                }
              }
            }, label: {
              if isUploading {
                ProgressView()
                  .tint(.white)
              } else {
                Label("Done", systemImage: "arrow.up")
              }
            }
          )
          .disabled(!isValid || isUploading)
        }
      }
    }
    .alert(alertTitle, isPresented: $presentAlert, actions: {
      Button("Okay", role: .close) { }
    }, message: {
      Text(alertContent)
    })
  }
  
  var isValid: Bool {
    return (
      viewModel.selectedUser != nil && viewModel.selectedReason != nil &&
      (viewModel.selectedReason != .etcReason || (1...viewModel.maxEtcDetailsLength).contains(viewModel.etcDetails.count))
    )
  }
  
  private func showAlert(title: String, content: String) {
    alertTitle = title
    alertContent = content
    presentAlert = true
  }
}

#Preview {
  TaxiReportView(room: TaxiRoom.mock)
}
