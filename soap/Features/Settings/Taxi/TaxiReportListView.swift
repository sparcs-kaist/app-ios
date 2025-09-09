//
//  TaxiReportDetailView.swift
//  soap
//
//  Created by 하정우 on 8/9/25.
//

import SwiftUI

struct TaxiReportListView: View {
  @State private var taxiReportType: TaxiReport.ReportType = .reported
  @State private var vm: TaxiReportListViewModelProtocol
  
  init(vm: TaxiReportListViewModelProtocol = TaxiReportListViewModel()) {
    _vm = State(initialValue: vm)
  }
  
  var body: some View {
    ScrollView {
      Picker("Report Type", selection: $taxiReportType) {
        ForEach(TaxiReport.ReportType.allCases, id: \.rawValue) { item in
          Text(item.rawValue).tag(item)
        }
      }
      .pickerStyle(.segmented)
      .padding(.bottom)
      Group {
        switch vm.state {
          case .loaded:
            loadedView
          case .loading:
            loadingView
          case .error(let message):
          ContentUnavailableView("Error", systemImage: "wifi.exclamationmark", description: Text(message))
        }
      }.transition(.opacity.animation(.easeInOut(duration: 0.3)))
    }
    .padding()
    .background(Color.secondarySystemBackground)
    .task {
      await vm.fetchReports()
    }
  }
  
  private var loadingView: some View {
    Group {
      TaxiReportDetailRow(report: TaxiReport(id: UUID().uuidString, nickname: "자신감 있는 유체역학_8c249", reportType: .reported, reason: .etc, etcDetail: "Not showing up at the scheduled time", reportedAt: Date()))
      TaxiReportDetailRow(report: TaxiReport(id: UUID().uuidString, nickname: "자신감 있는 유체역학_8c249", reportType: .reported, reason: .etc, etcDetail: "Not showing up at the scheduled time", reportedAt: Date()))
    }
    .redacted(reason: .placeholder)
  }
  
  private var loadedView: some View {
    Group {
      switch taxiReportType {
        case .reported:
          reportViewList(reports: vm.reports.reported)
        case .reporting:
          reportViewList(reports: vm.reports.reporting)
      }
    }.transition(.opacity.animation(.easeInOut(duration: 0.3)))
  }
  
  private func reportViewList(reports: [TaxiReport]) -> some View {
    Group {
      if (reports.isEmpty) {
        ContentUnavailableView("No Reports", systemImage: "list.bullet.clipboard")
      }
      ForEach(reports) {
        TaxiReportDetailRow(report: $0)
      }
    }
  }
}

#Preview("Loading State") {
  let vm = MockTaxiReportDetailViewModel()
  vm.state = .loading
  
  return TaxiReportListView(vm: vm)
}

#Preview("Loaded State") {
  let vm = MockTaxiReportDetailViewModel()
  vm.reports = (reported: [TaxiReport(id: UUID().uuidString, nickname: "자신감 있는 유체역학_8c249", reportType: .reported, reason: .etc, etcDetail: "Not showing up at the scheduled time", reportedAt: Date())], reporting: [TaxiReport(id: UUID().uuidString, nickname: "자신감 있는 유체역학_8c249", reportType: .reported, reason: .etc, etcDetail: "Not showing up at the scheduled time", reportedAt: Date()), TaxiReport(id: UUID().uuidString, nickname: "자신감 있는 유체역학_8c249", reportType: .reported, reason: .etc, etcDetail: "Not showing up at the scheduled time", reportedAt: Date())])
  vm.state = .loaded
  
  return TaxiReportListView(vm: vm)
}

#Preview("Error State") {
  let vm = MockTaxiReportDetailViewModel()
  vm.state = .error(message: "Network error")
  
  return TaxiReportListView(vm: vm)
}
