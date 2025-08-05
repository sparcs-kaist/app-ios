//
//  TaxiChat.swift
//  soap
//
//  Created by Soongyu Kwon on 16/07/2025.
//

import Foundation

struct TaxiChat: Identifiable, Equatable, Hashable, Sendable {
  enum ChatType: String {
    // User sent type
    case text               // normal message
    case s3img              // S3 uploaded image
    case settlement         // settlement message
    case payment            // payment message
    case account            // account message

    // General type
    case entrance = "in"   // enterance message
    case exit = "out"       // exit message

    // Bot sent type
    case share
    case departure
    case arrival
    
    case unknown
  }

  let id = UUID()
  let roomID: String
  let type: ChatType
  let authorID: String?
  let authorName: String?
  let authorProfileURL: URL?
  let authorIsWithdrew: Bool?
  let content: String
  let time: Date
  let isValid: Bool
  let inOutNames: [String]?
}
