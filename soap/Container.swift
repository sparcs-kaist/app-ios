//
//  Container.swift
//  soap
//
//  Created by Soongyu Kwon on 09/07/2025.
//

import Foundation
import Factory
import Moya
import BuddyDomain
import BuddyDataCore
import BuddyDataiOS

extension Container {
  // MARK: - Storage
  private var tokenStorage: Factory<TokenStorageProtocol> {
    self { TokenStorage() }.singleton
  }

  private var userStorage: Factory<UserStorageProtocol> {
    self { UserStorage() }.singleton
  }
  
  // MARK: - Helper
  @MainActor
  var crashlyticsHelper: Factory<CrashlyticsHelper> {
    self { @MainActor in CrashlyticsHelper() }.singleton
  }

  // MARK: - Networking
  private var authPlugin: Factory<AccessTokenPlugin> {
    self {
      let tokenStorage = self.tokenStorage.resolve()
      return AccessTokenPlugin { _ in
        return tokenStorage.getAccessToken() ?? ""
      }
    }
  }

  // MARK: - Repositories

  var authRepository: Factory<AuthRepositoryProtocol> {
    self { AuthRepository(provider: MoyaProvider<AuthTarget>()) }
  }
  
  var versionRepository: Factory<VersionRepositoryProtocol> {
    self { VersionRepository(provider: MoyaProvider<VersionTarget>()) }
  }

  // MARK: Taxi
  var taxiRoomRepository: Factory<TaxiRoomRepositoryProtocol> {
    self { TaxiRoomRepository(provider: MoyaProvider<TaxiRoomTarget>(plugins: [self.authPlugin.resolve()])) }
  }

  var taxiUserRepository: Factory<TaxiUserRepositoryProtocol> {
    self { TaxiUserRepository(provider: MoyaProvider<TaxiUserTarget>(plugins: [self.authPlugin.resolve()])) }
  }

  var taxiChatRepository: Factory<TaxiChatRepositoryProtocol> {
    self {
      TaxiChatRepository(
        provider: MoyaProvider<TaxiChatTarget>(plugins: [self.authPlugin.resolve()])
      )
    }
  }

  var taxiReportRepository: Factory<TaxiReportRepositoryProtocol> {
    self {
      TaxiReportRepository(
        provider: MoyaProvider<TaxiReportTarget>(plugins: [self.authPlugin.resolve()])
      )
    }
  }

  // MARK: Ara
  var araUserRepository: Factory<AraUserRepositoryProtocol> {
    self { AraUserRepository(provider: MoyaProvider<AraUserTarget>(plugins: [self.authPlugin.resolve()])) }
  }

  var araBoardRepository: Factory<AraBoardRepositoryProtocol> {
    self {
      AraBoardRepository(
        provider: MoyaProvider<AraBoardTarget>(
          plugins: [
            self.authPlugin.resolve()
          ]
        )
      )
    }
  }

  var araCommentRepository: Factory<AraCommentRepositoryProtocol> {
    self {
      AraCommentRepository(provider: MoyaProvider<AraCommentTarget>(plugins: [
        self.authPlugin.resolve()
      ]))
    }
  }

  // MARK: Feed
  var feedUserRepository: Factory<FeedUserRepositoryProtocol> {
    self {
      FeedUserRepository(provider: MoyaProvider<FeedUserTarget>(plugins: [
        self.authPlugin.resolve()
      ]))
    }
  }

  var feedPostRepository: Factory<FeedPostRepositoryProtocol> {
    self {
      FeedPostRepository(provider: MoyaProvider<FeedPostTarget>(plugins: [
        self.authPlugin.resolve()
      ]))
    }
  }

  var feedCommentRepository: Factory<FeedCommentRepositoryProtocol> {
    self {
      FeedCommentRepository(provider: MoyaProvider<FeedCommentTarget>(plugins: [
        self.authPlugin.resolve()
      ]))
    }
  }

  var feedImageRepository: Factory<FeedImageRepositoryProtocol> {
    self {
      FeedImageRepository(provider: MoyaProvider<FeedImageTarget>(plugins: [
        self.authPlugin.resolve()
      ]))
    }
  }

  // MARK: OTL
  var otlUserRepository: Factory<OTLUserRepositoryProtocol> {
    self {
      OTLUserRepository(provider: MoyaProvider<OTLUserTarget>(plugins: [
        self.authPlugin.resolve()
      ]))
    }
  }

  var otlTimetableRepository: Factory<OTLTimetableRepositoryProtocol> {
    self {
      OTLTimetableRepository(provider: MoyaProvider<OTLTimetableTarget>(plugins: [
        self.authPlugin.resolve()
      ]))
    }
  }

  var otlLectureRepository: Factory<OTLLectureRepositoryProtocol> {
    self {
      OTLLectureRepository(provider: MoyaProvider<OTLLectureTarget>(plugins: [
        self.authPlugin.resolve()
      ]))
    }
  }
  
  var otlCourseRepository: Factory<OTLCourseRepositoryProtocol> {
    self {
      OTLCourseRepository(provider: MoyaProvider<OTLCourseTarget>(plugins: [
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

  private var taxiChatService: Factory<TaxiChatServiceProtocol> {
    self {
      TaxiChatService(tokenStorage: self.tokenStorage.resolve())
    }.singleton
  }

  var sessionBridgeService: Factory<SessionBridgeServiceProtocol> {
    self {
       SessionBridgeService()
    }.singleton
  }

  // MARK: - Use Cases
  @MainActor
  var authUseCase: Factory<AuthUseCaseProtocol> {
    self {
      @MainActor in AuthUseCase(
        authenticationService: self.authenticationService.resolve(),
        tokenStorage: self.tokenStorage.resolve(),
        araUserRepository: self.araUserRepository.resolve(),
        feedUserRepository: self.feedUserRepository.resolve(),
        otlUserRepository: self.otlUserRepository.resolve()
      )
    }.singleton
  }

  var userUseCase: Factory<UserUseCaseProtocol> {
    self {
      UserUseCase(
        taxiUserRepository: self.taxiUserRepository.resolve(),
        feedUserRepository: self.feedUserRepository.resolve(),
        araUserRepository: self.araUserRepository.resolve(),
        otlUserRepository: self.otlUserRepository.resolve(),
        userStorage: self.userStorage.resolve()
      )
    }.singleton
  }

  @MainActor
  var taxiChatUseCase: ParameterFactory<TaxiRoom, TaxiChatUseCaseProtocol> {
    self {
      @MainActor in TaxiChatUseCase(
        taxiChatService: self.taxiChatService.resolve(),
        userUseCase: self.userUseCase.resolve(),
        taxiChatRepository: self.taxiChatRepository.resolve(),
        taxiRoomRepository: self.taxiRoomRepository.resolve(),
        room: $0
      )
    }
  }
  
  @MainActor
  var taxiLocationUseCase: Factory<TaxiLocationUseCaseProtocol> {
    self {
      @MainActor in TaxiLocationUseCase(taxiRoomRepository: self.taxiRoomRepository.resolve())
    }
  }
  
  @MainActor
  var taxiRoomUseCase: Factory<TaxiRoomUseCaseProtocol> {
    self {
      @MainActor in TaxiRoomUseCase(taxiRoomRepository: self.taxiRoomRepository.resolve(), userStorage: self.userStorage.resolve())
    }
  }

  @MainActor
  var foundationModelsUseCase: Factory<FoundationModelsUseCaseProtocol> {
    self {
      @MainActor in FoundationModelsUseCase()
    }
  }
  
  @MainActor
  var timetableUseCase: Factory<TimetableUseCaseProtocol> {
    self {
      @MainActor in TimetableUseCase(
        userUseCase: self.userUseCase.resolve(),
        otlTimetableRepository: self.otlTimetableRepository.resolve(),
        sessionBridgeService: self.sessionBridgeService.resolve()
      )
    }.singleton
  }
}
