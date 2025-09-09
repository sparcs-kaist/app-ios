//
//  TaxiReportDetailRow.swift
//  soap
//
//  Created by 하정우 on 8/9/25.
//

import SwiftUI

struct TaxiReportDetailRow: View {
  var report: TaxiReport
  
  var body: some View {
    VStack {
      switch report.reason {
      case .etc:
        RowElementView(title: "Reason", content: "Other reasons")
      case .noShow:
        RowElementView(title: "Reason", content: "Not showing up")
      case .noSettlement:
        RowElementView(title: "Reason", content: "No settlement")
      }
      Divider().padding(.vertical, 4)
      if (report.nickname != nil) && report.reportType == .reporting {
        RowElementView(title: "Nickname", content: report.nickname!).padding(.bottom, 4)
      }
      RowElementView(title: "Date", content: report.reportedAt.formattedString).padding(.bottom, 4)
      if report.reason == .etc {
        HStack(alignment: .top) {
          Text("Other reasons")
          Spacer()
          Text(report.etcDetail)
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
      TaxiReportDetailRow(report: TaxiReport(id: UUID().uuidString, nickname: "자신감 있는 유체역학_8c249", reportType: .reporting, reason: .etc, etcDetail: "Not showing up at the scheduled time", reportedAt: Date()))
        .padding(.horizontal)
      TaxiReportDetailRow(report: TaxiReport(id: UUID().uuidString, nickname: "자신감 있는 유체역학_8c249", reportType: .reported, reason: .etc, etcDetail: "Not showing up at the scheduled time", reportedAt: Date()))
        .padding(.horizontal)
    }
  }
  .ignoresSafeArea()
}
