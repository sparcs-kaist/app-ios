//
//  MoyaError+Extensions.swift
//  soap
//
//  Created by 하정우 on 1/7/26.
//

import Foundation
import Moya

extension MoyaError {
  var toAPIError: Error {
    guard let response = self.response else { return self }
    guard let error = try? response.map(APIErrorResponse.self) else { return self }
    
    return error
  }
}
