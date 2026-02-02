//
//  CrashlyticsHelper.swift
//  soap
//
//  Created by 하정우 on 10/7/25.
//

import Foundation
import FirebaseCrashlytics
import BuddyDomain

public final class CrashlyticsService: CrashlyticsServiceProtocol {
  private let userUseCase: UserUseCaseProtocol?

  public init(userUseCase: UserUseCaseProtocol?) {
    self.userUseCase = userUseCase
  }

  public func recordException(error: Error) {
    let userUseCase = self.userUseCase
    
    Task {
      let userID: String? = await userUseCase?.taxiUser?.id
      Crashlytics.crashlytics().record(error: error, userInfo: ["id": userID ?? "unauthorized"])
    }
  }
}
