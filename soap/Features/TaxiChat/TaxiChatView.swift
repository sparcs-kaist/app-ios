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

  @State private var viewModel = TaxiChatViewModel()

  @State private var text: String = ""
  @State private var hasScrolledToBottom: Bool = false
  @FocusState private var isFocused: Bool

  var body: some View {
    ScrollViewReader { proxy in
      chatScrollView(proxy: proxy)
    }
    .navigationTitle(Text(room.title))
    .navigationSubtitle(Text("\(room.source.title.localized()) → \(room.destination.title.localized())"))
    .navigationBarTitleDisplayMode(.inline)
    .toolbar { toolbarContent }
    .safeAreaBar(edge: .bottom) { inputBar }
    .toolbar(.hidden, for: .tabBar)
    .onAppear {
      viewModel.connect(to: room)
      hasScrolledToBottom = false
    }
  }

  private func chatScrollView(proxy: ScrollViewProxy) -> some View {
    ScrollView {
      LazyVStack(spacing: 16) {
        // First date header (top of chat)
        if let firstDate = viewModel.groupedChats.first?.chatGroup.first?.time {
          TaxiChatDayMessage(date: firstDate)
        }

        ForEach(viewModel.groupedChats.indices, id: \.self) { index in
          let group = viewModel.groupedChats[index]
          let isMe = group.isMe
          let authorName = group.chatGroup.first?.authorName
          let authorID = group.chatGroup.first?.authorID
          let authorProfileImageURL = group.chatGroup.first?.authorProfileURL
          let currentDate = group.chatGroup.first?.time

          // Insert date label if day changes from previous group
          if index > 0,
             let current = currentDate,
             let previous = viewModel.groupedChats[index - 1].chatGroup.first?.time,
             !Calendar.current.isDate(current, inSameDayAs: previous) {
            TaxiChatDayMessage(date: current)
          }

          if group.chatGroup.first?.type == .entrance || group.chatGroup.first?.type == .exit {
            TaxiChatGeneralMessage(authorName: authorName ?? "unknown", type: group.chatGroup.first?.type ?? .entrance)
          } else {
            TaxiChatUserWrapper(
              authorID: authorID,
              authorName: authorName,
              authorProfileImageURL: authorProfileImageURL,
              date: currentDate,
              isMe: isMe
            ) {
              ForEach(group.chatGroup.indices, id: \.self) { i in
                let message = group.chatGroup[i]
                let type: TaxiChat.ChatType = message.type
                switch type {
                case .text:
                  TaxiChatBubble(
                    content: message.content,
                    showTip: i == group.chatGroup.count - 1,
                    isMe: isMe
                  )
                case .departure:
                  TaxiDepartureBubble(room: room)
                case .arrival:
                  TaxiArrivalBubble()
                default:
                  Text(type.rawValue)
                }
              }
            }
          }
        }

        Color.clear
          .frame(height: 1)
          .id("BOTTOM")
      }
      .padding(.leading)
      .padding(.trailing, 8)
    }
    .onChange(of: viewModel.groupedChats) {
      if !hasScrolledToBottom {
        proxy.scrollTo("BOTTOM", anchor: .bottom)
        hasScrolledToBottom = true
      }
    }
  }

  private var inputBar: some View {
    HStack {
      Menu {
        Button("Send Payment", systemImage: "wonsign.circle") { }
        Button("Request Settlement", systemImage: "square.and.pencil") { }
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
        TextField("Chat as \(viewModel.nickname ?? "unknown")", text: $text)
          .padding(.leading, 4)
          .focused($isFocused)

        Button("Send", systemImage: "arrow.up") { }
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
}

#Preview {
  NavigationStack {
    TaxiChatView(room: TaxiRoom.mock)
  }
}
