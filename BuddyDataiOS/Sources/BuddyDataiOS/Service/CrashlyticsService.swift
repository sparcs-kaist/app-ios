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

    // Pass NetworkError those are not recordable
    if let networkError = error as? NetworkError,
       !networkError.isRecordable {
      return
    }

    Task {
      let userID: String? = await userUseCase?.taxiUser?.id
      Crashlytics.crashlytics().record(error: error, userInfo: ["id": userID ?? "unauthorized"])
    }
  }

  public func record(
    error: SourcedError,
    context: CrashContext
  ) {
    if let networkError = error as? NetworkError,
       !networkError.isRecordable {
      return
    }

    let userUseCase = self.userUseCase

    Task.detached(priority: .utility) {

      let userID = await userUseCase?.taxiUser?.id ?? "unauthorized"

      let crashlytics = Crashlytics.crashlytics()

      crashlytics.setCustomValue(context.feature, forKey: "feature")
      crashlytics.setCustomValue(context.action, forKey: "action")
      crashlytics.setCustomValue(error.source.rawValue, forKey: "source")
      crashlytics.setCustomValue(userID, forKey: "user_id")

      context.metadata.forEach {
        crashlytics.setCustomValue($0.value, forKey: $0.key)
      }

      crashlytics.record(error: error)
    }
  }

  public func record(
    error: Error,
    context: CrashContext
  ) {
    if let networkError = error as? NetworkError,
       !networkError.isRecordable {
      return
    }

    let userUseCase = self.userUseCase

    Task.detached(priority: .utility) {

      let userID = await userUseCase?.taxiUser?.id ?? "unauthorized"

      let crashlytics = Crashlytics.crashlytics()

      crashlytics.setCustomValue(context.feature, forKey: "feature")
      crashlytics.setCustomValue(context.action, forKey: "action")
      crashlytics.setCustomValue(ErrorSource.unknown.rawValue, forKey: "source")
      crashlytics.setCustomValue(userID, forKey: "user_id")

      context.metadata.forEach {
        crashlytics.setCustomValue($0.value, forKey: $0.key)
      }

      crashlytics.record(error: error)
    }
  }
}
