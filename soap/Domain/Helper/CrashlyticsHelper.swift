//
//  CrashlyticsHelper.swift
//  soap
//
//  Created by 하정우 on 10/7/25.
//

import Foundation
import FirebaseCrashlytics
import Moya
import Alamofire

@MainActor
@Observable
final class CrashlyticsHelper {
  var showAlert: Bool = false
  var alertMessage: LocalizedStringResource = ""
  
  func recordException(error: Error, showAlert: Bool = true, alertMessage: LocalizedStringResource = "Something went wrong. Please try again later.") {
    if let error = error as? MoyaError,
       case .underlying(let afError, _) = error,
       let underlyingError = (afError as? Alamofire.AFError)?.underlyingError,
       [NSURLErrorNotConnectedToInternet, NSURLErrorDataNotAllowed].contains((underlyingError as NSError).code)
    {
      self.showAlert = showAlert
      self.alertMessage = "You are not connected to the Internet."
      return
    }
    
    Crashlytics.crashlytics().record(error: error as NSError)
    self.showAlert = showAlert
    self.alertMessage = alertMessage
  }
}
