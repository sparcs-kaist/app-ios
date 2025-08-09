//
//  TaxiReportDetailView.swift
//  soap
//
//  Created by 하정우 on 8/9/25.
//

import SwiftUI

struct TaxiReportDetailView: View {
  enum TaxiReportType: String, CaseIterable {
    case reported
    case received
  }
  
  @State private var taxiReportType: TaxiReportType = .reported
  
  var body: some View {
    VStack(spacing: 0) {
      Picker("Report Type", selection: $taxiReportType) {
        ForEach(TaxiReportType.allCases, id: \.rawValue) { item in
          Text(item.rawValue.capitalized).tag(item)
        }
      }
      .pickerStyle(.segmented)
      .padding(.bottom)
      ScrollView {
        VStack(spacing: 10) {
          TaxiReportDetailRow(reason: "Other reasons", nickname: "자신감 있는 유체역학_8c249", reportedAt: Calendar.current.date(byAdding: .day, value: 1, to: Date()) ?? Date(), detailedReason: "Not showing up at the scheduled time")
          TaxiReportDetailRow(reason: "Other reasons", nickname: "자신감 있는 유체역학_8c249", reportedAt: Calendar.current.date(byAdding: .day, value: 1, to: Date()) ?? Date(), detailedReason: "Not showing up at the scheduled time")
        }
      }
    }.padding()
      .background(Color.secondarySystemBackground)
  }
}

#Preview {
  NavigationStack {
    TaxiReportDetailView()
  }
}
