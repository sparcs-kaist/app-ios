//
//  TaxiChatView.swift
//  soap
//
//  Created by Soongyu Kwon on 14/07/2025.
//

import SwiftUI
import Foundation

struct TaxiChatView: View {
  let room: TaxiRoom

  @State private var viewModel: TaxiChatViewModel

  @State private var text: String = ""
  @State private var topChatID: String? = nil
  @State private var isLoadingMore: Bool = false
  @FocusState private var isFocused: Bool

  init(room: TaxiRoom) {
    self.room = room
    _viewModel = State(initialValue: TaxiChatViewModel(room: room))
  }

  var body: some View {
    ScrollViewReader { proxy in
      contentView(proxy: proxy)
    }
    .navigationTitle(Text(room.title))
    .navigationSubtitle(Text("\(room.source.title.localized()) → \(room.destination.title.localized())"))
    .navigationBarTitleDisplayMode(.inline)
    .toolbar { toolbarContent }
    .safeAreaBar(edge: .bottom) { inputBar }
    .toolbar(.hidden, for: .tabBar)
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
                    TaxiDepartureBubble(room: room)
                  case .arrival:
                    TaxiArrivalBubble()
                  case .settlement:
                    TaxiChatSettlementBubble()
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
        Button("Send Payment", systemImage: "wonsign.circle") { }
        Button("Request Settlement", systemImage: "square.and.pencil") {
          viewModel.commitSettlement()
        }
        Button("Photo Library", systemImage: "photo.on.rectangle") { }
      } label: {
        Label("More", systemImage: "plus")
          .labelStyle(.iconOnly)
          .padding()
          .fontWeight(.semibold)
          .contentShape(.circle)
      }
      .glassEffect(.regular.interactive(), in: .circle)

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
      .glassEffect(.regular.interactive())
    }
    .padding(isFocused ? [.horizontal, .vertical] : [.horizontal])
  }

  @ToolbarContentBuilder
  private var toolbarContent: some ToolbarContent {
    ToolbarItem(placement: .topBarTrailing) {
      Menu("More", systemImage: "ellipsis") { }
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
}

#Preview {
  NavigationStack {
    TaxiChatView(room: TaxiRoom.mock)
  }
}
