//
//  TaxiReportDetailRow.swift
//  soap
//
//  Created by 하정우 on 8/9/25.
//

import SwiftUI

struct TaxiReportDetailRow: View {
  var report: TaxiReport
  var reportType: TaxiReportType
  
  var body: some View {
    VStack {
      switch report.reason {
      case .etcReason:
        RowElementView(title: "Reason", content: "Other reasons")
      case .noShow:
        RowElementView(title: "Reason", content: "Not showing up")
      case .noSettlement:
        RowElementView(title: "Reason", content: "No settlement")
      }
      Divider().padding(.vertical, 4)
      if reportType == .outgoing {
        RowElementView(title: "Nickname", content: report.reportedUser.nickname).padding(.bottom, 4)
      }
      RowElementView(title: "Date", content: report.time.formattedString).padding(.bottom, 4)
      if report.reason == .etcReason {
        HStack(alignment: .top) {
          Text("Other reasons")
          Spacer()
          Text(report.etcDetails)
            .foregroundStyle(.secondary)
            .multilineTextAlignment(.trailing)
        }
      }
    }
    .padding()
    .background(Color.systemBackground)
    .clipShape(.rect(cornerRadius: 28))
  }
}

#Preview {
  ZStack {
    Color.secondarySystemBackground
    VStack {
      TaxiReportDetailRow(report: .mock, reportType: .incoming)
        .padding(.horizontal)
      TaxiReportDetailRow(report: .mock, reportType: .outgoing)
        .padding(.horizontal)
    }
  }
  .ignoresSafeArea()
}
