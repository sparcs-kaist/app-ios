//
//  TaxiChat+Mockable.swift
//  soap
//
//  Created by Soongyu Kwon on 17/07/2025.
//

import Foundation
import BuddyDomain

extension TaxiChat: Mockable {
  static var mock: TaxiChat {
    mockList[0]
  }

  static var mockList: [TaxiChat] {
    let baseDate = Date()
    let roomID = "mock-room-id"
    
    return [
      // Alice enters first
      TaxiChat(
        roomID: roomID,
        type: .entrance,
        authorID: "user1",
        authorName: "Alice",
        authorProfileURL: URL(string: "https://sparcs-taxi-dev.s3.ap-northeast-2.amazonaws.com/profile-img/default/NupjukOTL.png"),
        authorIsWithdrew: false,
        content: "",
        time: baseDate.addingTimeInterval(-3600), // 1 hour ago
        isValid: true,
        inOutNames: ["Alice"]
      ),
      
      // Alice's first message
      TaxiChat(
        roomID: roomID,
        type: .text,
        authorID: "user1",
        authorName: "Alice",
        authorProfileURL: URL(string: "https://sparcs-taxi-dev.s3.ap-northeast-2.amazonaws.com/profile-img/default/NupjukOTL.png"),
        authorIsWithdrew: false,
        content: "Hello! Anyone want to share a taxi?",
        time: baseDate.addingTimeInterval(-3500),
        isValid: true,
        inOutNames: []
      ),
      
      // Bob enters
      TaxiChat(
        roomID: roomID,
        type: .entrance,
        authorID: "user2",
        authorName: "Bob",
        authorProfileURL: URL(string: "https://sparcs-taxi-dev.s3.ap-northeast-2.amazonaws.com/profile-img/default/GooseOTL.png"),
        authorIsWithdrew: false,
        content: "",
        time: baseDate.addingTimeInterval(-3400),
        isValid: true,
        inOutNames: ["Bob"]
      ),
      
      // Bob's response
      TaxiChat(
        roomID: roomID,
        type: .text,
        authorID: "user2",
        authorName: "Bob",
        authorProfileURL: URL(string: "https://sparcs-taxi-dev.s3.ap-northeast-2.amazonaws.com/profile-img/default/GooseOTL.png"),
        authorIsWithdrew: false,
        content: "Yes! I'd like to join too",
        time: baseDate.addingTimeInterval(-3350),
        isValid: true,
        inOutNames: []
      ),
      
      // Alice's follow-up
      TaxiChat(
        roomID: roomID,
        type: .text,
        authorID: "user1",
        authorName: "Alice",
        authorProfileURL: URL(string: "https://sparcs-taxi-dev.s3.ap-northeast-2.amazonaws.com/profile-img/default/NupjukOTL.png"),
        authorIsWithdrew: false,
        content: "Great! What time should we leave?",
        time: baseDate.addingTimeInterval(-3200),
        isValid: true,
        inOutNames: []
      ),
      
      // Bob's time suggestion
      TaxiChat(
        roomID: roomID,
        type: .text,
        authorID: "user2",
        authorName: "Bob",
        authorProfileURL: URL(string: "https://sparcs-taxi-dev.s3.ap-northeast-2.amazonaws.com/profile-img/default/GooseOTL.png"),
        authorIsWithdrew: false,
        content: "How about 2 PM?",
        time: baseDate.addingTimeInterval(-3100),
        isValid: true,
        inOutNames: []
      ),
      
      // Charlie enters
      TaxiChat(
        roomID: roomID,
        type: .entrance,
        authorID: "user3",
        authorName: "Charlie",
        authorProfileURL: URL(string: "https://sparcs-taxi-dev.s3.ap-northeast-2.amazonaws.com/profile-img/default/NupjukOTL.png"),
        authorIsWithdrew: false,
        content: "",
        time: baseDate.addingTimeInterval(-2800),
        isValid: true,
        inOutNames: ["Charlie"]
      ),
      
      // Charlie's message
      TaxiChat(
        roomID: roomID,
        type: .text,
        authorID: "user3",
        authorName: "Charlie",
        authorProfileURL: URL(string: "https://sparcs-taxi-dev.s3.ap-northeast-2.amazonaws.com/profile-img/default/NupjukOTL.png"),
        authorIsWithdrew: false,
        content: "Mind if I join? I'm going to the same destination",
        time: baseDate.addingTimeInterval(-2750),
        isValid: true,
        inOutNames: []
      ),
      
      // Account sharing
//      TaxiChat(
//        roomID: roomID,
//        type: .account,
//        authorID: "user1",
//        authorName: "Alice",
//        authorProfileURL: URL(string: "https://sparcs-taxi-dev.s3.ap-northeast-2.amazonaws.com/profile-img/default/NupjukOTL.png"),
//        authorIsWithdrew: false,
//        content: "Shared payment account info",
//        time: baseDate.addingTimeInterval(-2600),
//        isValid: true,
//        inOutNames: []
//      ),
      
      // Someone leaves
      TaxiChat(
        roomID: roomID,
        type: .exit,
        authorID: "user3",
        authorName: "Charlie",
        authorProfileURL: URL(string: "https://sparcs-taxi-dev.s3.ap-northeast-2.amazonaws.com/profile-img/default/NupjukOTL.png"),
        authorIsWithdrew: false,
        content: "",
        time: baseDate.addingTimeInterval(-2400),
        isValid: true,
        inOutNames: ["Charlie"]
      ),
      
      // Final conversation before departure
      TaxiChat(
        roomID: roomID,
        type: .text,
        authorID: "user1",
        authorName: "Alice",
        authorProfileURL: URL(string: "https://sparcs-taxi-dev.s3.ap-northeast-2.amazonaws.com/profile-img/default/NupjukOTL.png"),
        authorIsWithdrew: false,
        content: "Alright, let's meet at the pickup location",
        time: baseDate.addingTimeInterval(-2000),
        isValid: true,
        inOutNames: []
      ),
      
      // Departure message
      TaxiChat(
        roomID: roomID,
        type: .departure,
        authorID: nil,
        authorName: nil,
        authorProfileURL: nil,
        authorIsWithdrew: nil,
        content: "",
        time: baseDate.addingTimeInterval(-1800), // 30 minutes ago
        isValid: true,
        inOutNames: []
      ),
      
      // During ride
      TaxiChat(
        roomID: roomID,
        type: .text,
        authorID: "user1",
        authorName: "Alice",
        authorProfileURL: URL(string: "https://sparcs-taxi-dev.s3.ap-northeast-2.amazonaws.com/profile-img/default/NupjukOTL.png"),
        authorIsWithdrew: false,
        content: "We've departed!",
        time: baseDate.addingTimeInterval(-1700),
        isValid: true,
        inOutNames: []
      ),
      
      TaxiChat(
        roomID: roomID,
        type: .text,
        authorID: "user2",
        authorName: "Bob",
        authorProfileURL: URL(string: "https://sparcs-taxi-dev.s3.ap-northeast-2.amazonaws.com/profile-img/default/GooseOTL.png"),
        authorIsWithdrew: false,
        content: "Traffic is lighter than expected, we should arrive early",
        time: baseDate.addingTimeInterval(-1200),
        isValid: true,
        inOutNames: []
      ),
      
      // Arrival message
      TaxiChat(
        roomID: roomID,
        type: .arrival,
        authorID: nil,
        authorName: nil,
        authorProfileURL: nil,
        authorIsWithdrew: nil,
        content: "",
        time: baseDate.addingTimeInterval(-600), // 10 minutes ago
        isValid: true,
        inOutNames: []
      ),
      
      // Settlement message
      TaxiChat(
        roomID: roomID,
        type: .settlement,
        authorID: "user2",
        authorName: "Bob",
        authorProfileURL: URL(string: "https://sparcs-taxi-dev.s3.ap-northeast-2.amazonaws.com/profile-img/default/GooseOTL.png"),
        authorIsWithdrew: false,
        content: "",
        time: baseDate.addingTimeInterval(-300), // 5 minutes ago
        isValid: true,
        inOutNames: []
      ),
      
      // Payment message
      TaxiChat(
        roomID: roomID,
        type: .payment,
        authorID: "user1",
        authorName: "Alice",
        authorProfileURL: URL(string: "https://sparcs-taxi-dev.s3.ap-northeast-2.amazonaws.com/profile-img/default/NupjukOTL.png"),
        authorIsWithdrew: false,
        content: "",
        time: baseDate.addingTimeInterval(-180), // 3 minutes ago
        isValid: true,
        inOutNames: []
      ),
      
      // Final thank you message
      TaxiChat(
        roomID: roomID,
        type: .text,
        authorID: "user2",
        authorName: "Bob",
        authorProfileURL: URL(string: "https://sparcs-taxi-dev.s3.ap-northeast-2.amazonaws.com/profile-img/default/GooseOTL.png"),
        authorIsWithdrew: false,
        content: "Arrived safely! Thank you",
        time: baseDate.addingTimeInterval(-60),
        isValid: true,
        inOutNames: []
      )
    ]
  }
}

extension TaxiChatGroup: Mockable {
  static var mock: TaxiChatGroup {
    mockList[0]
  }
  
  static var mockList: [TaxiChatGroup] {
    let chats = TaxiChat.mockList
    let currentUserID = "user1" // Alice is current user
    
    // Group chats by time and author (simplified grouping logic)
    var groups: [TaxiChatGroup] = []
    var currentGroup: [TaxiChat] = []
    let calendar = Calendar.current
    
    for chat in chats {
      if chat.type == .entrance || chat.type == .exit {
        // Flush current group if any
        if !currentGroup.isEmpty {
          let time = currentGroup.first?.time ?? Date()
          let isMe = currentGroup.first?.authorID == currentUserID
          groups.append(TaxiChatGroup(
            id: time.toISO8601,
            chats: currentGroup,
            lastChatID: currentGroup.last?.id,
            authorID: currentGroup.first?.authorID,
            authorName: currentGroup.first?.authorName,
            authorProfileURL: currentGroup.first?.authorProfileURL,
            authorIsWithdrew: currentGroup.first?.authorIsWithdrew,
            time: time,
            isMe: isMe,
            isGeneral: false
          ))
          currentGroup = []
        }
        
        // Add general message group
        groups.append(TaxiChatGroup(
          id: chat.time.toISO8601,
          chats: [chat],
          lastChatID: nil,
          authorID: chat.authorID,
          authorName: chat.authorName,
          authorProfileURL: chat.authorProfileURL,
          authorIsWithdrew: chat.authorIsWithdrew,
          time: chat.time,
          isMe: chat.authorID == currentUserID,
          isGeneral: true
        ))
        continue
      }
      
      if currentGroup.isEmpty {
        currentGroup.append(chat)
        continue
      }
      
      let lastChat = currentGroup.last!
      let isSameAuthor = chat.authorID == lastChat.authorID
      let isSameMinute = calendar.isDate(chat.time, equalTo: lastChat.time, toGranularity: .minute)
      
      if isSameAuthor && isSameMinute {
        currentGroup.append(chat)
      } else {
        // Flush current group
        let time = currentGroup.first?.time ?? Date()
        let isMe = currentGroup.first?.authorID == currentUserID
        groups.append(TaxiChatGroup(
          id: time.toISO8601,
          chats: currentGroup,
          lastChatID: currentGroup.last?.id,
          authorID: currentGroup.first?.authorID,
          authorName: currentGroup.first?.authorName,
          authorProfileURL: currentGroup.first?.authorProfileURL,
          authorIsWithdrew: currentGroup.first?.authorIsWithdrew,
          time: time,
          isMe: isMe,
          isGeneral: false
        ))
        currentGroup = [chat]
      }
    }
    
    // Flush remaining group
    if !currentGroup.isEmpty {
      let time = currentGroup.first?.time ?? Date()
      let isMe = currentGroup.first?.authorID == currentUserID
      groups.append(TaxiChatGroup(
        id: time.toISO8601,
        chats: currentGroup,
        lastChatID: currentGroup.last?.id,
        authorID: currentGroup.first?.authorID,
        authorName: currentGroup.first?.authorName,
        authorProfileURL: currentGroup.first?.authorProfileURL,
        authorIsWithdrew: currentGroup.first?.authorIsWithdrew,
        time: time,
        isMe: isMe,
        isGeneral: false
      ))
    }
    
    return groups
  }
} 
