//
//  TaxiReportDetailRow.swift
//  soap
//
//  Created by 하정우 on 8/9/25.
//

import SwiftUI
import BuddyDomain

struct TaxiReportDetailRow: View {
  var report: TaxiReport
  var reportType: TaxiReportType
  
  var body: some View {
    VStack {
      switch report.reason {
      case .etcReason:
        RowElementView(title: String(localized: "Reason"), content: String(localized: "ETC"))
      case .noShow:
        RowElementView(title: String(localized: "Reason"), content: String(localized: "Didn't come on time"))
      case .noSettlement:
        RowElementView(title: String(localized: "Reason"), content: String(localized: "Didn't send money"))
      }
      Divider().padding(.vertical, 4)
      if reportType == .outgoing {
        RowElementView(title: String(localized: "Nickname"), content: report.reportedUser.nickname).padding(.bottom, 4)
      }
      RowElementView(title: String(localized: "Date"), content: report.time.formattedString).padding(.bottom, 4)
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
