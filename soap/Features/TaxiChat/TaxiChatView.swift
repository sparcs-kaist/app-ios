//
//  TaxiChatView.swift
//  soap
//
//  Created by Soongyu Kwon on 14/07/2025.
//

import SwiftUI
import Foundation

struct TaxiChatView: View {
  @State private var viewModel: TaxiChatViewModel

  @Environment(\.openURL) private var openURL
  @Environment(\.dismiss) private var dismiss

  @State private var text: String = ""
  @State private var topChatID: String? = nil
  @State private var isLoadingMore: Bool = false

  @State private var showCallTaxiAlert: Bool = false
  @State private var showErrorAlert: Bool = false
  @State private var errorMessage: String = ""

  @FocusState private var isFocused: Bool

  init(room: TaxiRoom) {
    _viewModel = State(initialValue: TaxiChatViewModel(room: room))
  }

  var body: some View {
    ScrollViewReader { proxy in
      contentView(proxy: proxy)
    }
    .navigationTitle(Text(viewModel.room.title))
    .navigationSubtitle(Text("\(viewModel.room.source.title.localized()) → \(viewModel.room.destination.title.localized())"))
    .navigationBarTitleDisplayMode(.inline)
    .toolbar { toolbarContent }
    .safeAreaBar(edge: .bottom) { inputBar }
    .toolbar(.hidden, for: .tabBar)
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
              HStack(alignment: .bottom, spacing: 4) {
                let showTimeLabel: Bool = groupedChat.lastChatID == chat.id

                // time label for this sender
                if showTimeLabel && groupedChat.isMe {
                  Text(groupedChat.time.formattedTime)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
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
                if showTimeLabel && !groupedChat.isMe {
                  Text(groupedChat.time.formattedTime)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
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
    .contentMargins(.bottom, 20)
  }

  private var inputBar: some View {
    HStack {
      Menu {
        Button("Send Payment", systemImage: "wonsign.circle") {
          viewModel.commitPayment()
        }
        .disabled(!viewModel.isCommitPaymentAvailable)
        Button("Request Settlement", systemImage: "square.and.pencil") {
          viewModel.commitSettlement()
        }
        .disabled(!viewModel.isCommitSettlementAvailable)

        Button("Photo Library", systemImage: "photo.on.rectangle") { }
      } label: {
        Label("More", systemImage: "plus")
          .labelStyle(.iconOnly)
          .padding()
          .fontWeight(.semibold)
          .contentShape(.circle)
      }
      .glassEffect(.clear.interactive(), in: .circle)

      HStack {
        TextField("Chat as \(viewModel.taxiUser?.nickname ?? "unknown")", text: $text)
          .padding(.leading, 4)
          .focused($isFocused)

        Button("Send", systemImage: "arrow.up") {
          viewModel.sendChat(text, type: .text)
          text = ""
        }
        .labelStyle(.iconOnly)
        .fontWeight(.semibold)
        .buttonStyle(.borderedProminent)
        .opacity(text.isEmpty ? 0 : 1)
        .disabled(text.isEmpty)
      }
      .padding(8)
      .glassEffect(.clear.interactive())
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
}

#Preview {
  NavigationStack {
    TaxiChatView(room: TaxiRoom.mock)
  }
}
