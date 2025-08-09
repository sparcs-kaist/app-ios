//
//  TaxiReportDetailRow.swift
//  soap
//
//  Created by 하정우 on 8/9/25.
//

import SwiftUI

struct TaxiReportDetailRow: View {
  var reason: String // TODO: implement enums
  var nickname: String?
  var reportedAt: Date
  var detailedReason: String?
  
  var body: some View {
    VStack {
      RowElementView(title: "Reason", content: "Other reasons")
      Divider().padding(.vertical, 4)
      if let nickname = nickname {
        RowElementView(title: "Nickname", content: nickname).padding(.bottom, 4)
      }
      RowElementView(title: "Date", content: reportedAt.formattedString).padding(.bottom, 4)
      if let detailedReason = detailedReason {
        HStack(alignment: .top) {
          Text("Other reasons")
          Spacer()
          Text(detailedReason)
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
    
    TaxiReportDetailRow(reason: "Other reasons", nickname: "자신감 있는 유체역학_8c249", reportedAt: Calendar.current.date(byAdding: .day, value: 1, to: Date()) ?? Date(), detailedReason: "Not showing up at the scheduled time")
      .padding(.horizontal)
  }
}
