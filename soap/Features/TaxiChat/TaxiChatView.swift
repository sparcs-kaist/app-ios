//
//  TaxiChatView.swift
//  soap
//
//  Created by Soongyu Kwon on 14/07/2025.
//

import SwiftUI
import Foundation
import PhotosUI

struct TaxiChatView: View {
  @State private var viewModel: TaxiChatViewModelProtocol

  @Environment(\.openURL) private var openURL
  @Environment(\.dismiss) private var dismiss

  @State private var text: String = ""
  @State private var topChatID: String? = nil
  @State private var isLoadingMore: Bool = false

  @State private var showCallTaxiAlert: Bool = false
  @State private var showErrorAlert: Bool = false
  @State private var errorMessage: String = ""

  @State private var showPhotosPicker: Bool = false
  @State private var selectedItem: PhotosPickerItem?
  @State private var selectedImage: UIImage?

  @State private var tappedImageID: String? = nil

  @Namespace private var namespace
  @FocusState private var isFocused: Bool

  init(room: TaxiRoom) {
    _viewModel = State(initialValue: TaxiChatViewModel(room: room))
  }
  
  init(viewModel: TaxiChatViewModelProtocol) {
    _viewModel = State(initialValue: viewModel)
  }

  var body: some View {
    ScrollViewReader { proxy in
      Group {
        switch viewModel.state {
        case .loading:
          loadingView
        case .loaded:
          contentView(proxy: proxy)
        case .error(let message):
          errorView(errorMessage: message)
        }
      }
      .transition(.opacity.animation(.easeInOut(duration: 0.3)))
    }
    .navigationTitle(Text(viewModel.room.title))
    .navigationSubtitle(Text("\(viewModel.room.source.title.localized()) → \(viewModel.room.destination.title.localized())"))
    .navigationBarTitleDisplayMode(.inline)
    .toolbar { toolbarContent }
    .safeAreaBar(edge: .bottom) { inputBar }
    .toolbar(.hidden, for: .tabBar)
    .photosPicker(
      isPresented: $showPhotosPicker,
      selection: $selectedItem,
      matching: .images,
      photoLibrary: .shared()
    )
    .onChange(of: selectedItem, loadImage)
    .navigationDestination(item: $tappedImageID) { id in
      FullscreenImageView(url: Constants.taxiChatImageURL.appending(path: id))
        .navigationTransition(.zoom(sourceID: id, in: namespace))
    }
    .alert(
      "Call Taxi",
      isPresented: $showCallTaxiAlert,
      actions: {
        Button("Open Kakao T", role: .confirm) {
          openKakaoT()
        }
        Button("Open Uber", role: .confirm) {
          openUber()
        }
        Button("Cancel", role: .cancel) { }
      },
      message: {
        Text(
          "You can launch the taxi app with the departure and destination already set. Once everyone has gathered at the departure point, press the button to call a taxi from \(viewModel.room.source.title.localized()) to \(viewModel.room.destination.title.localized())."
        )
      }
    )
    .alert("Error", isPresented: $showErrorAlert, actions: {
      Button("Okay", role: .close) { }
    }, message: {
      Text(errorMessage)
    })
    .task {
      await viewModel.setup()
      await viewModel.fetchInitialChats()
    }
  }

  private func contentView(proxy: ScrollViewProxy) -> some View {
    ScrollView {
      LazyVStack(spacing: 16) {
        Color.clear
          .frame(height: 1)
          .onAppear {
            loadMoreIfNeeded()
          }

        if let firstDate = viewModel.groupedChats.first?.time {
          TaxiChatDayMessage(date: firstDate)
        }

        ForEach(viewModel.groupedChats) { groupedChat in
          TaxiChatUserWrapper(
            authorID: groupedChat.authorID,
            authorName: groupedChat.authorName,
            authorProfileImageURL: groupedChat.authorProfileURL,
            date: groupedChat.time,
            isMe: groupedChat.isMe,
            isGeneral: groupedChat.isGeneral
          ) {
            ForEach(groupedChat.chats) { chat in
              let showTimeLabel: Bool = groupedChat.lastChatID == chat.id
              let otherParticipants: [TaxiParticipant] = viewModel.room.participants.filter {
                $0.id != viewModel.taxiUser?.oid
              }
              let readCount = otherParticipants.count(where: { $0.readAt <= chat.time })

              HStack(alignment: .bottom, spacing: 4) {
                // time label for this sender
                if groupedChat.isMe {
                  VStack(alignment: .trailing) {
                    if readCount > 0 {
                      Text("\(readCount)")
                        .font(.caption2)
                    }

                    if showTimeLabel {
                      Text(groupedChat.time.formattedTime)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    }
                  }
                }

                Group {
                  switch chat.type {
                  case .entrance, .exit:
                    TaxiChatGeneralMessage(authorName: chat.authorName, type: chat.type)
                  case .text:
                    TaxiChatBubble(
                      content: chat.content,
                      showTip: groupedChat.lastChatID == chat.id,
                      isMe: groupedChat.isMe
                    )
                  case .s3img:
                    TaxiChatImageBubble(id: chat.content)
                      .matchedTransitionSource(id: chat.content, in: namespace)
                      .onTapGesture {
                        tappedImageID = chat.content
                      }
                  case .departure:
                    TaxiDepartureBubble(room: viewModel.room)
                  case .arrival:
                    TaxiArrivalBubble()
                  case .settlement:
                    TaxiChatSettlementBubble()
                  case .payment:
                    TaxiChatPaymentBubble()
                  default:
                    Text(chat.type.rawValue)
                  }
                }

                // time label for other senders
                if !groupedChat.isMe {
                  VStack(alignment: .trailing) {
                    if readCount > 0 {
                      Text("\(readCount)")
                        .font(.caption2)
                    }

                    if showTimeLabel {
                      Text(groupedChat.time.formattedTime)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    }
                  }
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
    .onChange(of: viewModel.groupedChats) {
      proxy.scrollTo(topChatID, anchor: .top)
    }
    .scrollDismissesKeyboard(.interactively)
    .contentMargins(.bottom, 20)
  }

  private var inputBar: some View {
    HStack(alignment: .bottom) {
      Menu {
        Button("Send Payment", systemImage: "wonsign.circle") {
          viewModel.commitPayment()
        }
        .disabled(!viewModel.isCommitPaymentAvailable)
        Button("Request Settlement", systemImage: "square.and.pencil") {
          viewModel.commitSettlement()
        }
        .disabled(!viewModel.isCommitSettlementAvailable)

        Button("Photo Library", systemImage: "photo.on.rectangle") {
          showPhotosPicker = true
        }
      } label: {
        Label("More", systemImage: "plus")
          .labelStyle(.iconOnly)
          .fontWeight(.semibold)
          .frame(width: 48, height: 48)
          .contentShape(.circle)
      }
      .glassEffect(.clear.interactive(), in: .circle)

      HStack(alignment: .bottom) {
        if let image = selectedImage {
          Image(uiImage: image)
            .resizable()
            .scaledToFit()
            .frame(maxHeight: 200)
            .clipShape(.containerRelative)
            .overlay(alignment: .topTrailing) {
              Button("Remove", systemImage: "xmark") {
                selectedItem = nil
                selectedImage = nil
              }
              .labelStyle(.iconOnly)
              .padding(4)
              .font(.caption2)
              .glassEffect(.clear.interactive(), in: .circle)
              .padding(8)
            }

          Spacer()
        } else {
          TextField("Chat as \(viewModel.taxiUser?.nickname ?? "unknown")", text: $text)
            .padding(.leading, 4)
            .frame(height: 32)
            .focused($isFocused)
        }

        Button("Send", systemImage: "arrow.up") {
          if let image = selectedImage {
            Task {
              do {
                try await viewModel.sendImage(image)
                selectedItem = nil
                selectedImage = nil
              } catch {
                errorMessage = error.localizedDescription
                showErrorAlert = true
              }
            }
          } else {
            viewModel.sendChat(text, type: .text)
            text = ""
          }
        }
        .labelStyle(.iconOnly)
        .fontWeight(.semibold)
        .buttonStyle(.borderedProminent)
        .frame(height: 32)
        .opacity((text.isEmpty && selectedImage == nil) ? 0 : 1)
        .disabled((text.isEmpty && selectedImage == nil) || viewModel.isUploading)
        .overlay {
          if viewModel.isUploading {
            ProgressView()
          }
        }
      }
      .padding(8)
      .frame(maxWidth: .infinity)
//      .frame(height: 48)
      .glassEffect(.clear.interactive(), in: .rect(cornerRadius: 24))
    }
    .padding(isFocused ? [.horizontal, .vertical] : [.horizontal])
  }

  @ToolbarContentBuilder
  private var toolbarContent: some ToolbarContent {
    ToolbarItem(placement: .topBarTrailing) {
      Menu("More", systemImage: "ellipsis") {
        ControlGroup {
          Button("Share", systemImage: "square.and.arrow.up") { }
          Button("Call Taxi", systemImage: "car.fill") {
            showCallTaxiAlert = true
          }
          Button("Report", systemImage: "exclamationmark.triangle.fill") { }
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
              errorMessage = error.localizedDescription
              showErrorAlert = true
            }
          }
        }
        .disabled(!viewModel.isLeaveRoomAvailable)
      }
    }
  }

  private func loadMoreIfNeeded() {
    guard !isLoadingMore,
          let oldestDate = viewModel.groupedChats.first?.chats.first?.time else { return }

    // Prevent duplicate fetches
    guard !viewModel.fetchedDateSet.contains(oldestDate) else { return }
    topChatID = viewModel.groupedChats.first?.id

    viewModel.fetchedDateSet.insert(oldestDate)
    isLoadingMore = true

    Task {
      await viewModel.fetchChats(before: oldestDate)
      isLoadingMore = false
    }
  }

  private func openKakaoT() {
    if let url = URL(
      string: "kakaot://taxi/set?dest_lng=\(viewModel.room.destination.longitude)&dest_lat=\(viewModel.room.destination.latitude)&origin_lng=\(viewModel.room.source.longitude)&origin_lat=\(viewModel.room.source.latitude)"
    ) {
      openURL(url)
    }
  }

  private func openUber() {
    if let url = URL(
      string: "uber://?action=setPickup&client_id=a&&pickup[latitude]=\(viewModel.room.source.latitude)&pickup[longitude]=\(viewModel.room.source.longitude)&&dropoff[latitude]=\(viewModel.room.destination.latitude)&dropoff[longitude]=\(viewModel.room.destination.longitude)"
    ) {
      openURL(url)
    }
  }

  private func loadImage() {
    Task {
      guard let imageData = try await selectedItem?.loadTransferable(type: Data.self) else { return }
      guard let image = UIImage(data: imageData) else { return }

      self.selectedImage = image
    }
  }

  @ViewBuilder
  private var loadingView: some View {
    ScrollView {
      LazyVStack(spacing: 16) {
        Color.clear
          .frame(height: 1)

        if let firstDate = TaxiChatGroup.mockList.first?.time {
          TaxiChatDayMessage(date: firstDate)
        }

        ForEach(TaxiChatGroup.mockList.prefix(6)) { groupedChat in
          TaxiChatUserWrapper(
            authorID: groupedChat.authorID,
            authorName: groupedChat.authorName,
            authorProfileImageURL: groupedChat.authorProfileURL,
            date: groupedChat.time,
            isMe: false,
            isGeneral: groupedChat.isGeneral
          ) {
            ForEach(groupedChat.chats) { chat in
              let showTimeLabel: Bool = groupedChat.lastChatID == chat.id

              HStack(alignment: .bottom, spacing: 4) {
                Group {
                  switch chat.type {
                  case .entrance, .exit:
                    TaxiChatGeneralMessage(authorName: chat.authorName, type: chat.type)
                  case .text:
                    TaxiChatBubble(
                      content: chat.content,
                      showTip: groupedChat.lastChatID == chat.id,
                      isMe: false
                    )
                  case .departure:
                    TaxiDepartureBubble(room: TaxiRoom.mock)
                  case .arrival:
                    TaxiArrivalBubble()
                  case .settlement:
                    TaxiChatSettlementBubble()
                  case .payment:
                    TaxiChatPaymentBubble()
                  default:
                    Text(chat.type.rawValue)
                  }
                }

                if showTimeLabel {
                  VStack(alignment: .leading) {
                    Text("3")
                      .font(.caption2)

                    Text(groupedChat.time.formattedTime)
                      .font(.caption2)
                      .foregroundStyle(.secondary)
                  }
                }
              }
            }
          }
        }
      }
      .padding(.leading)
      .padding(.trailing, 8)
    }
    .defaultScrollAnchor(.bottom)
    .contentMargins(.bottom, 20)
    .redacted(reason: .placeholder)
    .disabled(true)
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
          // TODO: try again
        }
      }
    )
  }
}

// MARK: - Previews
#Preview("Loading State") {
  let vm = MockTaxiChatViewModel()
  vm.state = .loading
  return NavigationStack {
    TaxiChatView(viewModel: vm)
  }
}

#Preview("Loaded State") {
  let vm = MockTaxiChatViewModel()
  vm.groupedChats = Array(TaxiChatGroup.mockList)
  vm.state = .loaded(groupedChats: vm.groupedChats)
  vm.taxiUser = TaxiUser.mock
  return NavigationStack {
    TaxiChatView(viewModel: vm)
  }
}

#Preview("Error State") {
  let vm = MockTaxiChatViewModel()
  vm.state = .error(message: "Failed to load chats.")
  return NavigationStack {
    TaxiChatView(viewModel: vm)
  }
}

#Preview("Empty Chat") {
  let vm = MockTaxiChatViewModel()
  vm.groupedChats = []
  vm.state = .loaded(groupedChats: [])
  vm.taxiUser = TaxiUser.mock
  return NavigationStack {
    TaxiChatView(viewModel: vm)
  }
}
