//
//  TaxiReportDetailView.swift
//  soap
//
//  Created by 하정우 on 8/9/25.
//

import SwiftUI
import BuddyDomain
import FirebaseAnalytics

struct TaxiReportListView: View {
  @State private var taxiReportType: TaxiReportType = .incoming
  @State private var vm: TaxiReportListViewModelProtocol
  
  init(vm: TaxiReportListViewModelProtocol = TaxiReportListViewModel()) {
    _vm = State(initialValue: vm)
  }
  
  var body: some View {
    ScrollView {
      Picker("Report Type", selection: $taxiReportType) {
        ForEach(TaxiReportType.allCases, id: \.rawValue) { item in
          Text(item.description).tag(item)
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
    .analyticsScreen(name: "Taxi Report List", class: String(describing: Self.self))
  }
  
  private var loadingView: some View {
    Group {
      TaxiReportDetailRow(report: .mock, reportType: .incoming)
      TaxiReportDetailRow(report: .mock, reportType: .incoming)
    }
    .redacted(reason: .placeholder)
  }
  
  private var loadedView: some View {
    Group {
      switch taxiReportType {
      case .incoming:
        reportViewList(reports: vm.reports.incoming)
      case .outgoing:
        reportViewList(reports: vm.reports.outgoing)
      }
    }.transition(.opacity.animation(.easeInOut(duration: 0.3)))
  }
  
  private func reportViewList(reports: [TaxiReport]) -> some View {
    Group {
      if (reports.isEmpty) {
        ContentUnavailableView("No Reports", systemImage: "list.bullet.clipboard")
      }
      ForEach(reports) {
        TaxiReportDetailRow(report: $0, reportType: taxiReportType)
      }
    }
  }
}

//#Preview("Loading State") {
//  let vm = MockTaxiReportDetailViewModel()
//  vm.state = .loading
//  
//  return TaxiReportListView(vm: vm)
//}
//
//#Preview("Loaded State") {
//  let vm = MockTaxiReportDetailViewModel()
//  vm.reports = (incoming: TaxiReport.mockList, outgoing: TaxiReport.mockList)
//  vm.state = .loaded
//  
//  return TaxiReportListView(vm: vm)
//}
//
//#Preview("Error State") {
//  let vm = MockTaxiReportDetailViewModel()
//  vm.state = .error(message: "Network error")
//  
//  return TaxiReportListView(vm: vm)
//}
