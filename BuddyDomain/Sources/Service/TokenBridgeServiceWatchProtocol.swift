//
//  TokenBridgeServiceWatchProtocol.swift
//  BuddyDomain
//
//  Created by Soongyu Kwon on 06/10/2025.
//

import Foundation
import Combine

public protocol TokenBridgeServiceWatchProtocol {
  var tokenStatePublisher: AnyPublisher<TokenState?, Never> { get }
  var tokenState: TokenState? { get }

  func start()
}
