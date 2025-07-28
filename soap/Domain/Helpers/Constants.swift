//
//  Constants.swift
//  soap
//
//  Created by Soongyu Kwon on 09/07/2025.
//

import Foundation

enum Constants {
  static let authorisationURL = URL(string: "http://10.251.1.14:3000/api/auth/sparcsapp/login")
  static let taxiBackendURL = URL(string: "http://10.251.1.14:3000/api")!
  static let taxiSocketURL = URL(string: "http://10.251.1.14:3000")!
  static let taxiChatImageURL = URL(string: "https://sparcs-taxi-dev.s3.ap-northeast-2.amazonaws.com/chat-img")!
}
