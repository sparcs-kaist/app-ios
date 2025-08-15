//
//  TaxiNoticeListView.swift
//  soap
//
//  Created by 하정우 on 8/9/25.
//

import SwiftUI

struct TaxiNoticeView: View {
  @State private var vm: TaxiNoticeViewModelProtocol
  @State private var selectedNoticeURL: URL?
  
  init(vm: TaxiNoticeViewModelProtocol = TaxiNoticeViewModel()) {
    _vm = State(initialValue: vm)
  }
  
  var body: some View {
    Group {
      switch vm.state {
        case .loading:
          loadingView
        case .loaded:
          loadedView
        case .error(let message):
          ContentUnavailableView("An error occurred", systemImage: "wifi.exclamationmark", description: Text(message))
      }
    }
    .task {
        await vm.fetchNotices()
    }
    .fullScreenCover(item: $selectedNoticeURL) {
      SafariViewWrapper(url: $0)
    }
  }
  
  private var loadingView: some View {
    List {
      ForEach(0..<5) {
        Text("Notice \($0)")
      }
    }
    .redacted(reason: .placeholder)
  }
  
  private var loadedView: some View {
    List {
      ForEach(vm.notices) { notice in
        Button {
          selectedNoticeURL = notice.notionURL
        } label: {
          HStack {
            Text(notice.title)
            Spacer()
            Image(systemName: "chevron.right")
              .foregroundStyle(.secondary)
          }
          .foregroundStyle(.foreground)
        }
      }
    }
  }
}

#Preview("Loading State") {
  let vm = MockTaxiNoticeViewModel()
  vm.state = .loading
  
  return NavigationStack {
    TaxiNoticeView(vm: vm)
  }
}

#Preview("Loaded State") {
  let vm = MockTaxiNoticeViewModel()
  vm.notices = [TaxiNotice(id: UUID().uuidString, title: "Taxi Notice", notionURL: URL(string: "https://www.notion.so/sparcs/Taxi-238c25603b0b8043a406fcdc0f8c3fb2")!, isPinned: true, isActive: true, createdAt: Date(), updatedAt: Date())]
  vm.state = .loaded
  
  return NavigationStack {
    TaxiNoticeView(vm: vm)
  }
}

#Preview("Error State") {
  let vm = MockTaxiNoticeViewModel()
  vm.state = .error(message: "Network error")
  
  return NavigationStack {
    TaxiNoticeView(vm: vm)
  }
}
