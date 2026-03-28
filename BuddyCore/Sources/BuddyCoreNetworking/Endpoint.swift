//
//  Endpoint.swift
//  BuddyCore
//
//  Created by Soongyu Kwon on 28/03/2026.
//

import Alamofire
import Foundation

public protocol Endpoint: Sendable {
  var url: URL { get }
  var method: Alamofire.HTTPMethod { get }
  var parameters: Parameters? { get }
  var encoding: ParameterEncoding { get }
  var headers: HTTPHeaders { get }
}
