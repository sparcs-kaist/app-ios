//
//  TaxiReportView.swift
//  soap
//
//  Created by 김민찬 on 8/11/25.
//

import Foundation
import SwiftUI
import NukeUI
import Factory
import BuddyDomain
import FirebaseAnalytics

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
  @Injected(\.userUseCase) private var userUseCase: UserUseCaseProtocol?

  var body: some View {
    NavigationStack {
      Form {
        Section(String(localized: "Who?", bundle: .module)) {
          Picker(String(localized: "Select", bundle: .module), selection: $viewModel.selectedUser) {
            ForEach(room.participants.filter { $0.id != taxiUser?.oid }) { part in
              TaxiReportUser(user: part).tag(part)
            }
          }
          .pickerStyle(.inline)
          .labelsHidden()
        }
        .task {
          guard let userUseCase else { return }
          
          self.taxiUser = await userUseCase.taxiUser
        }
        
        Section {
          Picker(String(localized: "Reason", bundle: .module), selection: $viewModel.selectedReason) {
            Text("Select", bundle: .module)
              .tag(TaxiReport.Reason?.none)
              .selectionDisabled()
            Text("Didn't send money", bundle: .module)
              .tag(TaxiReport.Reason.noSettlement)
              .selectionDisabled(!room.isDeparted)
            Text("Didn't come on time", bundle: .module)
              .tag(TaxiReport.Reason.noShow)
              .selectionDisabled(!room.isDeparted)
            Text("ETC", bundle: .module).tag(TaxiReport.Reason.etcReason)
          }
          
          if viewModel.selectedReason == .etcReason {
            HStack {
              TextField(String(localized: "Details", bundle: .module), text: $viewModel.etcDetails)
              Text("\(viewModel.etcDetails.count)/\(viewModel.maxEtcDetailsLength)", bundle: .module)
                .foregroundStyle(viewModel.etcDetails.count > viewModel.maxEtcDetailsLength ? .orange : .secondary)
            }
          }
        } header: {
          Text("Why?", bundle: .module)
        } footer: {
          VStack(alignment: .leading, spacing: 8) {
            if !room.isDeparted {
              Text("Reports for unsettled payments and no-shows can only be submitted after the departure time.", bundle: .module)
            }
            if viewModel.selectedReason == .noSettlement {
              Text("An email will be sent asking them to send you the money.", bundle: .module)
            }
          }
        }
      }
      .navigationTitle(String(localized: "Report", bundle: .module))
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
//                  if error.isNetworkMoyaError {
//                    showAlert(title: String(localized: "Error", bundle: .module), content: String(localized: "You are not connected to the Internet.", bundle: .module))
//                  } else {
//                    viewModel.handleException(error)
//                    showAlert(title: String(localized: "Error", bundle: .module), content: String(localized: "An unexpected error occurred while reporting a user. Please try again later.", bundle: .module))
//                  }
                }
              }
            }, label: {
              if isUploading {
                ProgressView()
                  .tint(.white)
              } else {
                Label(String(localized: "Done", bundle: .module), systemImage: "arrow.up")
              }
            }
          )
          .disabled(!isValid || isUploading)
        }
      }
    }
    .alert(alertTitle, isPresented: $presentAlert, actions: {
      Button(String(localized: "Okay", bundle: .module), role: .close) { }
    }, message: {
      Text(alertContent)
    })
    .analyticsScreen(name: "Taxi Report", class: String(describing: Self.self))
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
