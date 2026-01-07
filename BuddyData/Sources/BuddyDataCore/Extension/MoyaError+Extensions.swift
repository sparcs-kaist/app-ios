//
//  MoyaError+Extensions.swift
//  soap
//
//  Created by 하정우 on 1/7/26.
//

import Foundation
import Moya
import BuddyDataCore

extension MoyaError {
  var toAPIError: Error {
    guard let response = self.response else { return self }
    
    do {
      return try response.map(APIErrorResponse.self)
    } catch {
      return error
    }
  }
}
