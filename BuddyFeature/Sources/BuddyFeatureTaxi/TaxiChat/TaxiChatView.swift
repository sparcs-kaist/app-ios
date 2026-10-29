//
//  TaxiChatView.swift
//  soap
//
//  Created by Soongyu Kwon on 14/07/2025.
//

import Foundation
import SwiftUI
import Factory
import BuddyDomain
import BuddyFeatureShared
import FirebaseAnalytics
import BuddyPreviewSupport
import os
import TipKit

private let logger = Logger(subsystem: "org.sparcs.soap", category: "TaxiChatView")

public struct TaxiChatView: View {
  @State private var viewModel: TaxiChatViewModelProtocol

  @Environment(\.openURL) private var openURL
  @Environment(\.dismiss) private var dismiss
  @Environment(\.horizontalSizeClass) private var horizontalSizeClass
  @Environment(\.verticalSizeClass) private var verticalSizeClass

  @State private var text: String = ""

  @State private var showPayMoneyAlert: Bool = false
  @State private var showSettlementAmountSheet: Bool = false

  @State private var tappedImageID: String? = nil
  /// The ride info, in a popover from the photos on a regular width and a sheet on a compact one.
  @State private var showRideInfo: Bool = false
  /// Horizontal centres on screen of where the bar puts the photos and of the title below them.
  /// The bar centres its items across its own width, which stops short of iPhone Duo's vertical
  /// bar, while the title is centred over the whole conversation, which runs on under it; the
  /// photos are moved by the difference so the two stay one above the other.
  @State private var ridePhotosMidX: CGFloat = 0
  @State private var rideTitleMidX: CGFloat = 0
  /// Set once you have left the room from the ride info, to finish leaving only after the ride
  /// info has finished closing; dismissing the chat while it is still on its way out can fail.
  @State private var hasLeftRoom: Bool = false

  @Namespace private var namespace

  @State private var unreadStore = Container.shared.taxiUnreadStore()

  /// Called after leaving the room, in place of `dismiss()`. A container that
  /// shows this view as a column root rather than a pushed screen passes it,
  /// since `dismiss()` there would close the container's own presentation.
  private let onLeave: (() -> Void)?

  public init(room: TaxiRoom, onLeave: (() -> Void)? = nil) {
    _viewModel = State(initialValue: TaxiChatViewModel(room: room))
    self.onLeave = onLeave
  }

  init(viewModel: TaxiChatViewModelProtocol, onLeave: (() -> Void)? = nil) {
    _viewModel = State(initialValue: viewModel)
    self.onLeave = onLeave
  }

  public var body: some View {
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
          scrollToBottomTrigger: 0,
          runsUnderVerticalBar: runsUnderVerticalBar
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
          scrollToBottomTrigger: viewModel.scrollToBottomTrigger,
          runsUnderVerticalBar: runsUnderVerticalBar
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
    .navigationBarTitleDisplayMode(.inline)
    .staticNavigationBar()
    .toolbar { toolbarContent }
    .safeAreaBar(edge: .top) {
      // Left out on a short screen, an iPhone in landscape, where with the keyboard up it would
      // leave room for a single line of the conversation; the photos in the bar still open the
      // ride's info.
      if verticalSizeClass != .compact {
        rideTitle
      }
    }
    .safeAreaBar(edge: .bottom) {
      TaxiChatInputBar(
        text: $text,
        nickname: viewModel.taxiUser?.nickname ?? String(localized: "unknown", bundle: .module),
        isUploading: viewModel.isUploading,
        isCommitPaymentAvailable: viewModel.isCommitPaymentAvailable,
        isCommitSettlementAvailable: viewModel.isCommitSettlementAvailable,
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
      .ignoringVerticalBar(runsUnderVerticalBar)
    }
    .toolbar(.hidden, for: .tabBar)
    .navigationDestination(item: $tappedImageID) { id in
      FullscreenImageView(url: Constants.taxiChatImageURL.appending(path: id))
        .navigationTransition(.zoom(sourceID: id, in: namespace))
    }
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
      isPresented: chatAlertPresented,
      actions: {
        Button(String(localized: "Okay", bundle: .module), role: .close) { }
      },
      message: {
        Text(viewModel.alertState?.message ?? "")
      }
    )
    .sheet(isPresented: $showSettlementAmountSheet) {
      TaxiSettlementAmountSheet(participantCount: viewModel.room.participants.count) { amount in
        viewModel.commitSettlement(settlementAmount: amount)
      }
    }
    .task {
      await viewModel.setup()
      await viewModel.fetchInitialChats()
    }
    // While the chat is on screen its chats are read as they arrive, so they neither count as
    // unread nor show as notifications.
    .onAppear {
      unreadStore?.enterRoom(viewModel.room.id)
    }
    .onDisappear {
      unreadStore?.leaveRoom(viewModel.room.id)
    }
    .analyticsScreen(name: "Taxi Chat", class: String(describing: Self.self))
  }

  @ToolbarContentBuilder
  private var toolbarContent: some ToolbarContent {
    ToolbarItem(placement: .principal) {
      Button(action: openRideInfo) {
        // Sized to fit inside the bar, which is shorter in landscape, so the photos stay clear
        // of the Dynamic Island and all of them can be tapped.
        TaxiRiderCluster(riders: viewModel.riders, size: verticalSizeClass == .compact ? 28 : 38)
          .matchedTransitionSource(id: Self.rideInfoTransitionID, in: namespace)
      }
      .buttonStyle(.plain)
      // From the photos, so on a wide display it points at whose ride it is; on a narrow one it
      // becomes a sheet that zooms out of them. Opening it from the title below lands here too.
      .popover(isPresented: $showRideInfo, arrowEdge: .top) {
        rideInfoPresentation
      }
      // The title below says the same to VoiceOver.
      .accessibilityHidden(true)
      .offset(x: ridePhotosOffset)
      .animation(.smooth, value: ridePhotosOffset)
      // Outside the offset, so this is where the bar put them, not where they were moved to.
      .onGeometryChange(for: CGFloat.self) { $0.frame(in: .global).midX } action: { ridePhotosMidX = $0 }
    }

  }

  private var rideTitle: some View {
    TaxiRideTitle(title: chatTitle, room: viewModel.room, action: openRideInfo)
      .popoverTip(rideInfoTip, arrowEdge: .top) { action in
        if action.id == RideInfoTip.openActionID {
          openRideInfo()
        }
      }
      .onGeometryChange(for: CGFloat.self) { $0.frame(in: .global).midX } action: { rideTitleMidX = $0 }
      // Forgotten when it leaves the screen, as in landscape, so the photos aren't lined up with
      // where it last was.
      .onDisappear { rideTitleMidX = 0 }
      .padding(.bottom, 4)
      .frame(maxWidth: .infinity)
      // Centred across the whole conversation, which can run on under iPhone Duo's vertical bar.
      .ignoringVerticalBar(runsUnderVerticalBar)
  }

  private func finishLeaving() {
    hasLeftRoom = false
    if let onLeave {
      onLeave()
    } else {
      dismiss()
    }
  }

  /// The chat's own error alert, held back while the ride info is open: that presents the same
  /// error itself, and on a wide display the chat beside it would present it a second time.
  private var chatAlertPresented: Binding<Bool> {
    Binding {
      viewModel.isAlertPresented && !showRideInfo
    } set: { isPresented in
      viewModel.isAlertPresented = isPresented
    }
  }

  private var ridePhotosOffset: CGFloat {
    guard ridePhotosMidX > 0, rideTitleMidX > 0 else { return 0 }
    return rideTitleMidX - ridePhotosMidX
  }

  /// Whether the conversation runs on under iPhone Duo's vertical bar. Only when the chat is a
  /// column beside the room list on a wide display does the bar hold nothing of its but the
  /// status; pushed, the bar holds its Back button, which the messages would pass under.
  private var runsUnderVerticalBar: Bool {
    onLeave != nil && horizontalSizeClass == .regular
  }

  private let rideInfoTip = RideInfoTip()

  private func openRideInfo() {
    // Found, however it was opened, so the tip doesn't come back.
    rideInfoTip.invalidate(reason: .actionPerformed)
    showRideInfo = true
  }

  private static let rideInfoTransitionID = "TaxiRideInfo"

  /// The ride info presents errors itself while it is open, since the chat beneath it cannot.
  private var rideInfoPresentation: some View {
    NavigationStack {
      TaxiRideInfoView(
        title: chatTitle,
        viewModel: viewModel,
        isErrorPresented: $viewModel.isAlertPresented,
        onLeave: {
          leaveRoom()
        }
      )
      .toolbar {
        ToolbarItem(placement: .cancellationAction) {
          Button(role: .close) {
            showRideInfo = false
          }
        }
      }
    }
    .onDisappear {
      if hasLeftRoom { finishLeaving() }
    }
    // The size the popover takes; a sheet ignores it.
    .frame(idealWidth: 400, idealHeight: 720)
    .presentationCompactAdaptation(.sheet)
    .navigationTransition(.zoom(sourceID: Self.rideInfoTransitionID, in: namespace))
  }

  private func leaveRoom() {
    Task {
      do {
        try await viewModel.leaveRoom()
        if showRideInfo {
          hasLeftRoom = true
          showRideInfo = false
        } else {
          finishLeaving()
        }
      } catch {
        logger.error("Failed to leave room: \(error.localizedDescription, privacy: .public)")
        viewModel.alertState = AlertState(title: String(localized: "Error", bundle: .module), message: error.localizedDescription)
        viewModel.isAlertPresented = true
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
  /// Lets this run on under iPhone Duo's vertical bar, while keeping every other inset, such as
  /// an iPhone's notch in landscape.
  @ViewBuilder
  func ignoringVerticalBar(_ isEnabled: Bool = true) -> some View {
    if #available(iOS 27.1, *), isEnabled {
      modifier(IgnoringVerticalBar())
    } else {
      self
    }
  }

  /// Stops the navigation bar minimising as the transcript scrolls. The title
  /// identifies the room and who is riding, and should stay put and legible
  /// while reading back through messages.
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

@available(iOS 27.1, *)
private struct IgnoringVerticalBar: ViewModifier {
  @Environment(\.toolbarVerticalEdge) private var verticalBarEdge

  func body(content: Content) -> some View {
    switch verticalBarEdge {
    case .leading: content.ignoresSafeArea(.container, edges: .leading)
    case .trailing: content.ignoresSafeArea(.container, edges: .trailing)
    case nil: content
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
