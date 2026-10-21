//
//  TaxiChatView.swift
//  soap
//
//  Created by Soongyu Kwon on 14/07/2025.
//

import Foundation
import SwiftUI
import BuddyDomain
import BuddyFeatureShared
import FirebaseAnalytics
import BuddyPreviewSupport
import os

private let logger = Logger(subsystem: "org.sparcs.soap", category: "TaxiChatView")

struct TaxiChatView: View {
  @State private var viewModel: TaxiChatViewModelProtocol

  @Environment(\.openURL) private var openURL
  @Environment(\.dismiss) private var dismiss

  @State private var text: String = ""

  @State private var showCallTaxiAlert: Bool = false
  @State private var showPayMoneyAlert: Bool = false
  @State private var showSettlementAmountSheet: Bool = false
  @State private var showReportSheet: Bool = false
  @State private var reportSheetDetent: PresentationDetent = .height(450)

  @State private var tappedImageID: String? = nil

  @Namespace private var namespace

  /// Called after leaving the room, in place of `dismiss()`. A container that
  /// shows this view as a column root rather than a pushed screen passes it,
  /// since `dismiss()` there would close the container's own presentation.
  private let onLeave: (() -> Void)?

  init(room: TaxiRoom, onLeave: (() -> Void)? = nil) {
    _viewModel = State(initialValue: TaxiChatViewModel(room: room))
    self.onLeave = onLeave
  }

  init(viewModel: TaxiChatViewModelProtocol, onLeave: (() -> Void)? = nil) {
    _viewModel = State(initialValue: viewModel)
    self.onLeave = onLeave
  }

  var body: some View {
    GeometryReader { reader in
      switch viewModel.state {
      case .loading:
        ChatCollectionView(
          items: Self.placeholderItems,
          room: viewModel.room,
          user: nil,
          isCommitPaymentAvailable: false,
          onCommitPayment: {},
          safeAreaInsets: reader.safeAreaInsets,
          scrollToBottomTrigger: 0
        )
        .redacted(reason: .placeholder)
        .disabled(true)
        .padding(.leading, -reader.safeAreaInsets.leading)
        .padding(.trailing, -reader.safeAreaInsets.trailing)
        .ignoresSafeArea(.all, edges: .vertical)
      case .loaded:
        ChatCollectionView(
          items: viewModel.renderItems,
          room: viewModel.room,
          user: viewModel.taxiUser,
          isCommitPaymentAvailable: viewModel.isCommitPaymentAvailable,
          onCommitPayment: {
            viewModel.commitPayment()
          },
          safeAreaInsets: reader.safeAreaInsets,
          scrollToBottomTrigger: viewModel.scrollToBottomTrigger
        )
        // Expand only by this column's measured side insets. Ignoring the
        // horizontal safe area here can extend under the neighboring column.
        // ChatCollectionView applies these insets to its rows, not its viewport.
        .padding(.leading, -reader.safeAreaInsets.leading)
        .padding(.trailing, -reader.safeAreaInsets.trailing)
        .ignoresSafeArea(.all, edges: .vertical)
      case .error(let message):
        errorView(errorMessage: message)
      }
    }
    .transition(.opacity.animation(.easeInOut(duration: 0.3)))
    .navigationTitle(Text(chatTitle))
    .navigationSubtitle(Text("\(viewModel.room.source.title.localized()) → \(viewModel.room.destination.title.localized())"))
    .navigationBarTitleDisplayMode(.inline)
    .staticNavigationBar()
    .toolbar { toolbarContent }
    .safeAreaBar(edge: .bottom) {
      TaxiChatInputBar(
        text: $text,
        nickname: viewModel.taxiUser?.nickname ?? String(localized: "unknown", bundle: .module),
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
          showSettlementAmountSheet = true
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
          viewModel.alertState = AlertState(title: String(localized: "Error", bundle: .module), message: message)
          viewModel.isAlertPresented = true
        }
      )
      // Pushed from the wide Taxi list, the chat spans the whole display:
      // keep the field a readable width, and on one side of a half-folded
      // iPhone Duo rather than across the crease.
      .contentWidth()
      .avoidingFold()
    }
    .toolbar(.hidden, for: .tabBar)
    .navigationDestination(item: $tappedImageID) { id in
      FullscreenImageView(url: Constants.taxiChatImageURL.appending(path: id))
        .navigationTransition(.zoom(sourceID: id, in: namespace))
    }
    .alert(
      String(localized: "Call Taxi", bundle: .module),
      isPresented: $showCallTaxiAlert,
      actions: {
        Button(String(localized: "Open Kakao T", bundle: .module), role: .confirm) {
          if let url = TaxiDeepLinkHelper.kakaoTURL(source: viewModel.room.source, destination: viewModel.room.destination) {
            openURL(url)
          }
        }
        Button(String(localized: "Open Uber", bundle: .module), role: .confirm) {
          if let url = TaxiDeepLinkHelper.uberURL(source: viewModel.room.source, destination: viewModel.room.destination) {
            openURL(url)
          }
        }
        Button(String(localized: "Cancel", bundle: .module), role: .cancel) { }
      },
      message: {
        Text(
          String(localized: "You can launch the taxi app with the departure and destination already set. Once everyone has gathered at the departure point, press the button to call a taxi from \(viewModel.room.source.title.localized()) to \(viewModel.room.destination.title.localized()).", bundle: .module)
        )
      }
    )
    .alert(
      String(localized: "Send Payment", bundle: .module),
      isPresented: $showPayMoneyAlert,
      actions: {
        Button(String(localized: "Open Kakao Pay", bundle: .module), role: .confirm) {
          if let url = TaxiDeepLinkHelper.kakaoPayURL(account: viewModel.account) {
            openURL(url)
          }
        }
        Button(String(localized: "Open Toss", bundle: .module), role: .confirm) {
          if let url = TaxiDeepLinkHelper.tossURL(account: viewModel.account) {
            openURL(url)
          }
        }
        Button(String(localized: "Already Sent", bundle: .module), role: .confirm) {
          viewModel.commitPayment()
        }
        Button(String(localized: "Cancel", bundle: .module), role: .cancel) { }
      },
      message: {
        Text(
          String(localized: "Select the app to send your payment. Tap Already Sent once you've completed the transfer.", bundle: .module)
        )
      }
    )
    .alert(
      viewModel.alertState?.title ?? String(localized: "Error", bundle: .module),
      isPresented: $viewModel.isAlertPresented,
      actions: {
        Button(String(localized: "Okay", bundle: .module), role: .close) { }
      },
      message: {
        Text(viewModel.alertState?.message ?? "")
      }
    )
    .sheet(isPresented: $showReportSheet) {
      TaxiReportView(room: viewModel.room)
        .presentationDragIndicator(.visible)
        // `.large` as well for when the participant list outgrows 450
        // points; the selection keeps 450 as the opening height.
        .presentationDetents([.height(450), .large], selection: $reportSheetDetent)
    }
    .sheet(isPresented: $showSettlementAmountSheet) {
      TaxiSettlementAmountSheet(participantCount: viewModel.room.participants.count) { amount in
        viewModel.commitSettlement(settlementAmount: amount)
      }
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
      // Not `ellipsis`: that is the system's overflow menu, which shares a
      // vertical bar with this item on iPhone Duo.
      Menu(String(localized: "More", bundle: .module), systemImage: "info.circle") {
        ControlGroup {
          ShareLink(item: URL(string: "https://taxi.dev.sparcs.org/invite/" + viewModel.room.id)!, message: Text("🚕 Looking for someone to ride with on \(viewModel.room.departAt.formattedString) from \(viewModel.room.source.title) to \(viewModel.room.destination.title)! 🚕", bundle: .module)) {
            Label(String(localized: "Share", bundle: .module), systemImage: "square.and.arrow.up")
          }
          Button(String(localized: "Call Taxi", bundle: .module), systemImage: "car.fill") {
            showCallTaxiAlert = true
          }
          Button(String(localized: "Report", bundle: .module), systemImage: "exclamationmark.triangle.fill") {
            reportSheetDetent = .height(450)
            showReportSheet = true
          }
          .disabled(viewModel.room.participants.count <= 1)
        }

        Divider()

        Label(viewModel.room.departAt.formattedString, systemImage: "calendar.badge.clock")

        Menu(
          String(localized: "Participants \(viewModel.room.participants.count)/\(viewModel.room.capacity)", bundle: .module),
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

        Button(String(localized: "Leave", bundle: .module), systemImage: "rectangle.portrait.and.arrow.right", role: .destructive) {
          Task {
            do {
              try await viewModel.leaveRoom()
              if let onLeave {
                onLeave()
              } else {
                dismiss()
              }
            } catch {
              logger.error("Failed to leave room: \(error.localizedDescription, privacy: .public)")
              viewModel.alertState = AlertState(title: String(localized: "Error", bundle: .module), message: error.localizedDescription)
              viewModel.isAlertPresented = true
            }
          }
        }
        .disabled(!viewModel.isLeaveRoomAvailable)
      }
    }
  }

  private var chatTitle: String {
    guard let emoji = viewModel.room.emojiIdentifier?.emoji else {
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
        Label(String(localized: "Error", bundle: .module), systemImage: "exclamationmark.triangle.fill")
      },
      description: {
        Text(errorMessage)
      },
      actions: {
        Button(String(localized: "Try Again", bundle: .module)) {
          Task {
            await viewModel.fetchInitialChats()
          }
        }
      }
    )
  }
}

private extension View {
  /// Stops the navigation bar minimising as the transcript scrolls. The title
  /// and subtitle identify the room, and should stay put and legible while
  /// reading back through messages.
  ///
  /// `toolbarMinimizationBehavior` is iOS 27.0; on 26 the bar already holds
  /// still unless the view is searchable, which this one is not.
  @ViewBuilder
  func staticNavigationBar() -> some View {
    if #available(iOS 27.0, *) {
      toolbarMinimizationBehavior(.never, for: .navigationBar)
    } else {
      self
    }
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
