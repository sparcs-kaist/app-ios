//
//  TaxiChatServiceProtocol.swift
//  soap
//
//  Created by Soongyu Kwon on 20/07/2025.
//

import Foundation
import Combine

protocol TaxiChatServiceProtocol {
  var chatsPublisher: AnyPublisher<[TaxiChat], Never> { get }
  var isConnectedPublisher: AnyPublisher<Bool, Never> { get }
}
