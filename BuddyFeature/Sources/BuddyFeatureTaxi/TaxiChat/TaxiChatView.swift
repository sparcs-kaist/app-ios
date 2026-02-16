//
//  TaxiChatView.swift
//  soap
//
//  Created by Soongyu Kwon on 14/07/2025.
//

import SwiftUI
import BuddyDomain

struct TaxiChatView: View {
  @State private var viewModel: TaxiChatViewModelProtocol

  @Environment(\.openURL) private var openURL
  @Environment(\.dismiss) private var dismiss

  @State private var text: String = ""

  @State private var showCallTaxiAlert: Bool = false
  @State private var showPayMoneyAlert: Bool = false
  @State private var showReportSheet: Bool = false

  @State private var tappedImageID: String? = nil
  @State private var scrollToBottomTrigger: Int = 0

  @Namespace private var namespace

  init(room: TaxiRoom) {
    _viewModel = State(initialValue: TaxiChatViewModel(room: room))
  }

  init(viewModel: TaxiChatViewModelProtocol) {
    _viewModel = State(initialValue: viewModel)
  }

  var body: some View {
    Group {
      switch viewModel.state {
      case .loading:
        chatListView(groups: Array(TaxiChatGroup.mockList.prefix(6)), isInteractive: false)
          .redacted(reason: .placeholder)
          .disabled(true)
      case .loaded:
        ChatList(items: viewModel.renderItems, room: viewModel.room, user: viewModel.taxiUser)
          .ignoresSafeArea()
      case .error(let message):
        errorView(errorMessage: message)
      }
    }
    .transition(.opacity.animation(.easeInOut(duration: 0.3)))
    .navigationTitle(Text(viewModel.room.title))
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
        onSendText: { message in
          viewModel.sendChat(message, type: .text)
          scrollToBottomTrigger += 1
        },
        onSendImage: { image in
          try await viewModel.sendImage(image)
          scrollToBottomTrigger += 1
        },
        onCommitSettlement: {
          viewModel.commitSettlement()
        },
        onShowPayMoneyAlert: {
          showPayMoneyAlert = true
        },
        onError: { message in
          viewModel.alertState = AlertState(title: "Error", message: message)
          viewModel.isAlertPresented = true
        },
        onFocusChange: { focused in
          if focused { scrollToBottomTrigger += 1 }
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
  }

  // isInteractive means data is actual loaded data. False means it is a mock and needs to be redacted.
  private func chatListView(groups: [TaxiChatGroup], isInteractive: Bool) -> some View {
    ScrollView {
      LazyVStack(spacing: 16) {
        Color.clear
          .frame(height: 1)
          .onAppear {
            if isInteractive {
              Task { await viewModel.loadMoreChats() }
            }
          }

        if let firstDate = groups.first?.time {
          TaxiChatDayMessage(date: firstDate)
        }

        ForEach(groups) { groupedChat in
          TaxiChatUserWrapper(
            authorID: groupedChat.authorID,
            authorName: groupedChat.authorName,
            authorProfileImageURL: groupedChat.authorProfileURL,
            date: groupedChat.time,
            isMe: isInteractive ? groupedChat.isMe : false,
            isGeneral: groupedChat.isGeneral,
            isWithdrawn: groupedChat.authorIsWithdrew ?? false,
            badge: isInteractive ? viewModel.hasBadge(authorID: groupedChat.authorID) : false
          ) {
            ForEach(groupedChat.chats) { chat in
              let showTimeLabel: Bool = groupedChat.lastChatID == chat.id

              HStack(alignment: .bottom, spacing: 4) {
                if isInteractive && groupedChat.isMe && groupedChat.lastChatID != nil {
                  TaxiChatReadReceipt(
                    readCount: readCount(for: chat),
                    showTimeLabel: showTimeLabel,
                    time: groupedChat.time.formattedTime,
                    alignment: .trailing
                  )
                }

                chatBubble(for: chat, in: groupedChat, isInteractive: isInteractive)

                if isInteractive && !groupedChat.isMe && groupedChat.lastChatID != nil {
                  TaxiChatReadReceipt(
                    readCount: readCount(for: chat),
                    showTimeLabel: showTimeLabel,
                    time: groupedChat.time.formattedTime,
                    alignment: .leading
                  )
                } else if !isInteractive && showTimeLabel {
                  TaxiChatReadReceipt(
                    readCount: 3,
                    showTimeLabel: true,
                    time: groupedChat.time.formattedTime,
                    alignment: .leading
                  )
                }
              }
            }
          }
          .id(groupedChat.id)
        }
      }
      .padding(.leading)
      .padding(.trailing, 8)
    }
    .defaultScrollAnchor(.bottom)
    .contentMargins(.bottom, 20)
  }

  @ViewBuilder
  private func chatBubble(for chat: TaxiChat, in groupedChat: TaxiChatGroup, isInteractive: Bool) -> some View {
    switch chat.type {
    case .entrance, .exit:
      TaxiChatGeneralMessage(authorName: chat.authorName, type: chat.type)
    case .text:
      TaxiChatBubble(
        content: chat.content,
        showTip: groupedChat.lastChatID == chat.id,
        isMe: isInteractive ? groupedChat.isMe : false
      )
    case .s3img:
      if isInteractive {
        TaxiChatImageBubble(id: chat.content)
          .matchedTransitionSource(id: chat.content, in: namespace)
          .onTapGesture {
            tappedImageID = chat.content
          }
      } else {
        TaxiChatImageBubble(id: chat.content)
      }
    case .departure:
      TaxiDepartureBubble(room: isInteractive ? viewModel.room : TaxiRoom.mock)
    case .arrival:
      TaxiArrivalBubble()
    case .settlement:
      TaxiChatSettlementBubble()
    case .payment:
      TaxiChatPaymentBubble()
    case .account:
      if isInteractive {
        TaxiChatAccountBubble(content: chat.content, isCommitPaymentAvailable: viewModel.isCommitPaymentAvailable) {
          showPayMoneyAlert = true
        }
      } else {
        TaxiChatAccountBubble(content: "BANK NUMBER", isCommitPaymentAvailable: true) { }
      }
    case .share:
      TaxiChatShareBubble(room: isInteractive ? viewModel.room : TaxiRoom.mock)
    default:
      Text(chat.type.rawValue)
    }
  }

  private func readCount(for chat: TaxiChat) -> Int {
    let otherParticipants = viewModel.room.participants.filter {
      $0.id != viewModel.taxiUser?.oid
    }
    return otherParticipants.count(where: { $0.readAt <= chat.time })
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
          "Participants \(viewModel.room.participants.count)/\(viewModel.room.capacity)",
          systemImage: "person.3"
        ) {
          ForEach(viewModel.room.participants) { participant in
            Text(participant.nickname)
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
//#Preview("Loading State") {
//  let vm = MockTaxiChatViewModel()
//  vm.state = .loading
//  return NavigationStack {
//    TaxiChatView(viewModel: vm)
//  }
//}
//
//#Preview("Loaded State") {
//  let vm = MockTaxiChatViewModel()
//  vm.groupedChats = Array(TaxiChatGroup.mockList)
//  vm.state = .loaded(groupedChats: vm.groupedChats)
//  vm.taxiUser = TaxiUser.mock
//  return NavigationStack {
//    TaxiChatView(viewModel: vm)
//  }
//}
//
//#Preview("Error State") {
//  let vm = MockTaxiChatViewModel()
//  vm.state = .error(message: "Failed to load chats.")
//  return NavigationStack {
//    TaxiChatView(viewModel: vm)
//  }
//}
//
//#Preview("Empty Chat") {
//  let vm = MockTaxiChatViewModel()
//  vm.groupedChats = []
//  vm.state = .loaded(groupedChats: [])
//  vm.taxiUser = TaxiUser.mock
//  return NavigationStack {
//    TaxiChatView(viewModel: vm)
//  }
//}
