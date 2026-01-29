//
//  Container.swift
//  BuddyDomain
//
//  Created by Soongyu Kwon on 27/01/2026.
//

import Foundation
import Factory

extension Container {

  // MARK: - Repositories
  public var authRepository: Factory<AuthRepositoryProtocol?> {
    promised()
  }

  // MARK:  Taxi
  public var taxiRoomRepository: Factory<TaxiRoomRepositoryProtocol?> {
    promised()
  }

  public var taxiUserRepository: Factory<TaxiUserRepositoryProtocol?> {
    promised()
  }

  public var taxiChatRepository: Factory<TaxiChatRepositoryProtocol?> {
    promised()
  }

  public var taxiReportRepository: Factory<TaxiReportRepositoryProtocol?> {
    promised()
  }

  // MARK: Ara
  public var araUserRepository: Factory<AraUserRepositoryProtocol?> {
    promised()
  }

  public var araBoardRepository: Factory<AraBoardRepositoryProtocol?> {
    promised()
  }

  public var araCommentRepository: Factory<AraCommentRepositoryProtocol?> {
    promised()
  }

  // MARK: Feed
  public var feedUserRepository: Factory<FeedUserRepositoryProtocol?> {
    promised()
  }

  public var feedPostRepository: Factory<FeedPostRepositoryProtocol?> {
    promised()
  }

  public var feedCommentRepository: Factory<FeedCommentRepositoryProtocol?> {
    promised()
  }

  public var feedImageRepository: Factory<FeedImageRepositoryProtocol?> {
    promised()
  }

  // MARK: OTL
  public var otlUserRepository: Factory<OTLUserRepositoryProtocol?> {
    promised()
  }

  public var otlTimetableRepository: Factory<OTLTimetableRepositoryProtocol?> {
    promised()
  }

  public var otlLectureRepository: Factory<OTLLectureRepositoryProtocol?> {
    promised()
  }

  public var otlCourseRepository: Factory<OTLCourseRepositoryProtocol?> {
    promised()
  }

  // MARK: - Use Cases
  public var authUseCase: Factory<AuthUseCaseProtocol?> {
    promised()
  }
}
