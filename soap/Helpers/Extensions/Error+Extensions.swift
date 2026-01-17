//
//  Error+Extensions.swift
//  soap
//
//  Created by 하정우 on 1/17/26.
//

import Foundation
import Moya
import Alamofire

extension Error {
  var isNetworkMoyaError: Bool {
    return (self as? MoyaError)
      .flatMap {
        if case let .underlying(afError, _) = $0 {
          return (afError as? Alamofire.AFError)?.underlyingError
        }
        return nil
      }
      .map { [NSURLErrorNotConnectedToInternet, NSURLErrorDataNotAllowed].contains(($0 as NSError).code) }
      ?? false
  }
}
