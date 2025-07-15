//
//  TaxiChatRequest.swift
//  soap
//
//  Created by Soongyu Kwon on 15/07/2025.
//

import Foundation

struct TaxiChatRequest {
  enum ChatRequestType: String {
    case text               // normal message
    case s3img              // S3 uploaded image
    case enterance = "in"   // enterance message
    case exit = "out"       // exit message
    case settlement         // settlement message
    case payment            // payment message
    case account            // account message
  }

  let roomID: String
  let type: ChatRequestType
  let content: String
}
