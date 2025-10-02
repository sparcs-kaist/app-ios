//
//  FeedReportView.swift
//  soap
//
//  Created by 하정우 on 10/2/25.
//

import SwiftUI

struct FeedReportView: View {
  let id: String
  let onReport: ((_ id: String, _ reason: FeedReportType, _ detail: String) async throws -> ())
  
  @Environment(\.dismiss) private var dismiss
  @State private var isUploading: Bool = false
  @State private var reason: FeedReportType = .abusiveLanguage
  @State private var detail: String = ""
  
  var body: some View {
    NavigationStack {
      ScrollView {
        VStack(alignment: .leading) {
          header
            .padding(.horizontal)
            .disabled(isUploading)

          TextField("Please write additional information (optional)", text: $detail, axis: .vertical)
            .submitLabel(.return)
            .writingToolsBehavior(.complete)
            .padding(.horizontal)
            .disabled(isUploading)
        }
        .padding(.vertical)
      }
    }
    .scrollDismissesKeyboard(.interactively)
    .navigationTitle(Text("Report"))
    .navigationBarTitleDisplayMode(.inline)
    .toolbar {
      ToolbarItem(placement: .topBarLeading) {
        Button("Close", systemImage: "xmark") {
          dismiss()
        }
      }
      ToolbarItem(placement: .topBarTrailing) {
        Button(
          role: .confirm,
          action: {
            Task {
              isUploading = true
              defer { isUploading = false }
              do {
                try await onReport(id, reason, detail)
                dismiss()
              } catch {
                // TODO: Handle Error here
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
      }
    }
  }
  
  var header: some View {
    HStack {
      Picker(selection: $reason, label: EmptyView()) {
        ForEach(FeedReportType.allCases) {
          Text($0.prettyString)
        }
      }
      .pickerStyle(.menu)
      .tint(.primary)
      .buttonStyle(.glass)
      Spacer()
    }
  }
}
