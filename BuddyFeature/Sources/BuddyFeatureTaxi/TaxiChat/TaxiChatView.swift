//
//  TaxiChatView.swift
//  soap
//
//  Created by Soongyu Kwon on 14/07/2025.
//

import SwiftUI
import BuddyDomain
import FirebaseAnalytics
import BuddyPreviewSupport

struct TaxiChatView: View {
  @State private var viewModel: TaxiChatViewModelProtocol

  @Environment(\.openURL) private var openURL
  @Environment(\.dismiss) private var dismiss

  @State private var text: String = ""

  @State private var showCallTaxiAlert: Bool = false
  @State private var showPayMoneyAlert: Bool = false
  @State private var showReportSheet: Bool = false

  @State private var tappedImageID: String? = nil

  @Namespace private var namespace

  init(room: TaxiRoom) {
    _viewModel = State(initialValue: TaxiChatViewModel(room: room))
  }

  init(viewModel: TaxiChatViewModelProtocol) {
    _viewModel = State(initialValue: viewModel)
  }

  var body: some View {
    GeometryReader { reader in
      switch viewModel.state {
      case .loading:
        ChatCollectionView(
          items: Self.placeholderItems,
          room: viewModel.room,
          user: nil,
          safeAreaInsets: reader.safeAreaInsets,
          scrollToBottomTrigger: 0
        )
        .redacted(reason: .placeholder)
        .disabled(true)
        .ignoresSafeArea()
      case .loaded:
        ChatCollectionView(
          items: viewModel.renderItems,
          room: viewModel.room,
          user: viewModel.taxiUser,
          safeAreaInsets: reader.safeAreaInsets,
          scrollToBottomTrigger: viewModel.scrollToBottomTrigger
        )
        .ignoresSafeArea()
      case .error(let message):
        errorView(errorMessage: message)
      }
    }
    .transition(.opacity.animation(.easeInOut(duration: 0.3)))
    .navigationTitle(Text(chatTitle))
    .navigationSubtitle(Text("\(viewModel.room.source.title.localized()) → \(viewModel.room.destination.title.localized())"))
    .navigationBarTitleDisplayMode(.inline)
    .toolbar { toolbarContent }
    .safeAreaBar(edge: .bottom) {
      TaxiChatInputBar(
        text: $text,
        nickname: viewModel.taxiUser?.nickname ?? "unknown",
        isUploading: viewModel.isUploading,
        isCommitPaymentAvailable: viewModel.isCommitPaymentAvailable,
        isCommitSettlementAvailable: viewModel.isCommitSettlementAvailable,
        isArrivalToggleEnabled: viewModel.isArrivalToggleEnabled,
        isArrived: $viewModel.isArrived,
        hasCarrier: $viewModel.hasCarrier,
        onSendText: { message in
          viewModel.sendChat(message, type: .text)
        },
        onSendImage: { image in
          try await viewModel.sendImage(image)
        },
        onCommitSettlement: {
          viewModel.commitSettlement()
        },
        onShowPayMoneyAlert: {
          showPayMoneyAlert = true
        },
        onUpdateArrival: { isArrived in
          viewModel.updateArrival(isArrived: isArrived)
        },
        onUpdateCarrier: { hasCarrier in
          viewModel.updateCarrier(hasCarrier: hasCarrier)
        },
        onError: { message in
          viewModel.alertState = AlertState(title: "Error", message: message)
          viewModel.isAlertPresented = true
        }
      )
    }
    .toolbar(.hidden, for: .tabBar)
    .navigationDestination(item: $tappedImageID) { id in
      FullscreenImageView(url: Constants.taxiChatImageURL.appending(path: id))
        .navigationTransition(.zoom(sourceID: id, in: namespace))
    }
    .alert(
      "Call Taxi",
      isPresented: $showCallTaxiAlert,
      actions: {
        Button("Open Kakao T", role: .confirm) {
          if let url = TaxiDeepLinkHelper.kakaoTURL(source: viewModel.room.source, destination: viewModel.room.destination) {
            openURL(url)
          }
        }
        Button("Open Uber", role: .confirm) {
          if let url = TaxiDeepLinkHelper.uberURL(source: viewModel.room.source, destination: viewModel.room.destination) {
            openURL(url)
          }
        }
        Button("Cancel", role: .cancel) { }
      },
      message: {
        Text(
          "You can launch the taxi app with the departure and destination already set. Once everyone has gathered at the departure point, press the button to call a taxi from \(viewModel.room.source.title.localized()) to \(viewModel.room.destination.title.localized())."
        )
      }
    )
    .alert(
      "Send Payment",
      isPresented: $showPayMoneyAlert,
      actions: {
        Button("Open Kakao Pay", role: .confirm) {
          if let url = TaxiDeepLinkHelper.kakaoPayURL(account: viewModel.account) {
            openURL(url)
          }
        }
        Button("Open Toss", role: .confirm) {
          if let url = TaxiDeepLinkHelper.tossURL(account: viewModel.account) {
            openURL(url)
          }
        }
        Button("Already Sent", role: .confirm) {
          viewModel.commitPayment()
        }
        Button("Cancel", role: .cancel) { }
      },
      message: {
        Text(
          "Select the app to send your payment. Tap Already Sent once you've completed the transfer."
        )
      }
    )
    .alert(
      viewModel.alertState?.title ?? "Error",
      isPresented: $viewModel.isAlertPresented,
      actions: {
        Button("Okay", role: .close) { }
      },
      message: {
        Text(viewModel.alertState?.message ?? "")
      }
    )
    .sheet(isPresented: $showReportSheet) {
      TaxiReportView(room: viewModel.room)
        .presentationDragIndicator(.visible)
        .presentationDetents([.height(450)])
    }
    .task {
      await viewModel.setup()
      await viewModel.fetchInitialChats()
    }
    .analyticsScreen(name: "Taxi Chat", class: String(describing: Self.self))
  }

  @ToolbarContentBuilder
  private var toolbarContent: some ToolbarContent {
    ToolbarItem(placement: .topBarTrailing) {
      Menu("More", systemImage: "ellipsis") {
        ControlGroup {
          ShareLink(item: URL(string: "https://taxi.dev.sparcs.org/invite/" + viewModel.room.id)!, message: Text(LocalizedStringResource("🚕 Looking for someone to ride with on \(viewModel.room.departAt.formattedString) from \(viewModel.room.source.title) to \(viewModel.room.destination.title)! 🚕"))) {
            Label("Share", systemImage: "square.and.arrow.up")
          }
          Button("Call Taxi", systemImage: "car.fill") {
            showCallTaxiAlert = true
          }
          Button("Report", systemImage: "exclamationmark.triangle.fill") {
            showReportSheet = true
          }
          .disabled(viewModel.room.participants.count <= 1)
        }

        Divider()

        Label(viewModel.room.departAt.formattedString, systemImage: "calendar.badge.clock")

        Menu(
          "Participants \(viewModel.room.participants.count)/\(viewModel.room.capacity)\nArrived \(viewModel.arrivedCount)/\(viewModel.room.participants.count)",
          systemImage: "person.3"
        ) {
          ForEach(viewModel.room.participants) { participant in
            if participant.hasCarrier {
              Label(participant.nickname, systemImage: "suitcase.rolling.and.suitcase.fill")
            } else {
              Text(participant.nickname)
            }
          }
        }

        Divider()

        Button("Leave", systemImage: "rectangle.portrait.and.arrow.right", role: .destructive) {
          Task {
            do {
              try await viewModel.leaveRoom()
              dismiss()
            } catch {
              viewModel.alertState = AlertState(title: "Error", message: error.localizedDescription)
              viewModel.isAlertPresented = true
            }
          }
        }
        .disabled(!viewModel.isLeaveRoomAvailable)
      }
    }
  }

  private var chatTitle: String {
    guard let emoji = viewModel.room.emojiIdentifier?.rawValue else {
      return viewModel.room.title
    }

    return "\(viewModel.room.title) \(emoji)"
  }

  private static let placeholderItems: [ChatRenderItem] = {
    let builder = ChatRenderItemBuilder(
      policy: TaxiGroupingPolicy(),
      positionResolver: ChatBubblePositionResolver(),
      presentationPolicy: DefaultMessagePresentationPolicy()
    )
    return builder.build(chats: TaxiChat.mockList, myUserID: nil)
  }()

  private func errorView(errorMessage: String) -> some View {
    ContentUnavailableView(
      label: {
        Label("Error", systemImage: "exclamationmark.triangle.fill")
      },
      description: {
        Text(errorMessage)
      },
      actions: {
        Button("Try Again") {
          Task {
            await viewModel.fetchInitialChats()
          }
        }
      }
    )
  }
}

// MARK: - Previews
#Preview("Loading State") {
  NavigationStack {
    TaxiChatView(viewModel: PreviewTaxiChatViewModel(state: .loading))
  }
}

#Preview("Loaded State") {
  NavigationStack {
    TaxiChatView(viewModel: PreviewTaxiChatViewModel(state: .loaded))
  }
}

#Preview("Error State") {
  NavigationStack {
    TaxiChatView(viewModel: PreviewTaxiChatViewModel(state: .error(message: "Something went wrong")))
  }
}
