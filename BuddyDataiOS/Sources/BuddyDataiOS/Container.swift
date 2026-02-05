//
//  Container.swift
//  BuddyDataiOS
//
//  Created by Soongyu Kwon on 27/01/2026.
//

import Foundation
import Factory
import BuddyDomain
import BuddyDataCore
import Moya

extension Container: @retroactive AutoRegistering {
  private var tokenStorage: Factory<TokenStorageProtocol> {
    self { TokenStorage() }.singleton
  }

  private var userStorage: Factory<UserStorageProtocol> {
    self { UserStorage() }.singleton
  }

  private var authPlugin: Factory<AccessTokenPlugin> {
    self {
      let tokenStorage = self.tokenStorage.resolve()
      return AccessTokenPlugin { _ in
        return tokenStorage.getAccessToken() ?? ""
      }
    }
  }

  // MARK: - Repositories
  private var feedPostRepository: Factory<FeedPostRepositoryProtocol> {
    self {
      FeedPostRepository(provider: MoyaProvider<FeedPostTarget>(plugins: [
        self.authPlugin.resolve()
      ]))
    }
  }

  private var feedCommentRepository: Factory<FeedCommentRepositoryProtocol> {
    self {
      FeedCommentRepository(provider: MoyaProvider<FeedCommentTarget>(plugins: [
        self.authPlugin.resolve()
      ]))
    }
  }

  // MARK: - Services
  private var authenticationService: Factory<AuthenticationServiceProtocol> {
    self {
      MainActor.assumeIsolated {
        AuthenticationService(authRepository: self.authRepository.resolve())
      }
    }.singleton
  }

  public func autoRegister() {

    // MARK: - Repositories
    authRepository.register {
      AuthRepository(provider: MoyaProvider<AuthTarget>())
    }

    versionRepository.register {
      VersionRepository(provider: MoyaProvider<VersionTarget>())
    }

    // MARK: Taxi
    taxiRoomRepository.register {
      TaxiRoomRepository(provider: MoyaProvider<TaxiRoomTarget>(plugins: [
        self.authPlugin.resolve()
      ]))
    }

    taxiUserRepository.register {
      TaxiUserRepository(provider: MoyaProvider<TaxiUserTarget>(plugins: [
        self.authPlugin.resolve()
      ]))
    }

    taxiChatRepository.register {
      TaxiChatRepository(
        provider: MoyaProvider<TaxiChatTarget>(plugins: [self.authPlugin.resolve()])
      )
    }

    taxiReportRepository.register {
      TaxiReportRepository(
        provider: MoyaProvider<TaxiReportTarget>(plugins: [self.authPlugin.resolve()])
      )
    }

    // MARK: Ara
    araUserRepository.register {
      AraUserRepository(provider: MoyaProvider<AraUserTarget>(plugins: [self.authPlugin.resolve()]))
    }

    araBoardRepository.register {
      AraBoardRepository(
        provider: MoyaProvider<AraBoardTarget>(
          plugins: [
            self.authPlugin.resolve()
          ]
        )
      )
    }

    araCommentRepository.register {
      AraCommentRepository(provider: MoyaProvider<AraCommentTarget>(plugins: [
        self.authPlugin.resolve()
      ]))
    }

    // MARK: Feed
    feedUserRepository.register {
      FeedUserRepository(provider: MoyaProvider<FeedUserTarget>(plugins: [
        self.authPlugin.resolve()
      ]))
    }

    feedImageRepository.register {
      FeedImageRepository(provider: MoyaProvider<FeedImageTarget>(plugins: [
        self.authPlugin.resolve()
      ]))
    }

    // MARK: OTL
    otlUserRepository.register {
      OTLUserRepository(provider: MoyaProvider<OTLUserTarget>(plugins: [
        self.authPlugin.resolve()
      ]))
    }

    otlTimetableRepository.register {
      OTLTimetableRepository(provider: MoyaProvider<OTLTimetableTarget>(plugins: [
        self.authPlugin.resolve()
      ]))
    }

    otlLectureRepository.register {
      OTLLectureRepository(provider: MoyaProvider<OTLLectureTarget>(plugins: [
        self.authPlugin.resolve()
      ]))
    }

    otlCourseRepository.register {
      OTLCourseRepository(provider: MoyaProvider<OTLCourseTarget>(plugins: [
        self.authPlugin.resolve()
      ]))
    }

    // MARK: - Services
    sessionBridgeService.register {
      SessionBridgeService()
    }
    .scope(.singleton)

    crashlyticsService.register {
      CrashlyticsService(userUseCase: self.userUseCase.resolve())
    }
    .scope(.singleton)

    taxiChatService.register {
      TaxiChatService(tokenStorage: self.tokenStorage.resolve())
    }
    .scope(.singleton)

    // MARK: - Use Cases
    authUseCase.register {
      AuthUseCase(
        authenticationService: self.authenticationService.resolve(),
        tokenStorage: self.tokenStorage.resolve(),
        araUserRepository: self.araUserRepository.resolve(),
        feedUserRepository: self.feedUserRepository.resolve(),
        otlUserRepository: self.otlUserRepository.resolve()
      )
    }
    .scope(.singleton)

    userUseCase.register {
      UserUseCase(
        taxiUserRepository: self.taxiUserRepository.resolve(),
        feedUserRepository: self.feedUserRepository.resolve(),
        araUserRepository: self.araUserRepository.resolve(),
        otlUserRepository: self.otlUserRepository.resolve(),
        userStorage: self.userStorage.resolve()
      )
    }
    .scope(.singleton)

    taxiChatUseCase.register {
      TaxiChatUseCase(
        taxiChatService: self.taxiChatService.resolve(),
        userUseCase: self.userUseCase.resolve(),
        taxiChatRepository: self.taxiChatRepository.resolve(),
        taxiRoomRepository: self.taxiRoomRepository.resolve(),
      )
    }

    taxiLocationUseCase.register {
      TaxiLocationUseCase(taxiRoomRepository: self.taxiRoomRepository.resolve())
    }

    taxiRoomUseCase.register {
      TaxiRoomUseCase(
        taxiRoomRepository: self.taxiRoomRepository.resolve(),
        userStorage: self.userStorage.resolve()
      )
    }

    foundationModelsUseCase.register {
      FoundationModelsUseCase()
    }

    timetableUseCase.register {
      TimetableUseCase(
        userUseCase: self.userUseCase.resolve(),
        otlTimetableRepository: self.otlTimetableRepository.resolve(),
        sessionBridgeService: self.sessionBridgeService.resolve()
      )
    }
    .scope(.singleton)

    feedPostUseCase.register {
      FeedPostUseCase(
        feedPostRepository: self.feedPostRepository.resolve(),
        crashlyticsService: self.crashlyticsService.resolve()
      )
    }

    feedCommentUseCase.register {
      FeedCommentUseCase(
        feedCommentRepository: self.feedCommentRepository.resolve(),
        crashlyticsService: self.crashlyticsService.resolve()
      )
    }
  }
}
