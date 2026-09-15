import Foundation
import BuddyDomain
@preconcurrency import Moya

public actor TimetableThemeRepository: TimetableThemeRepositoryProtocol {
  private let provider: MoyaProvider<TimetableThemeTarget>

  public init(provider: MoyaProvider<TimetableThemeTarget>) {
    self.provider = provider
  }

  public func share(_ theme: TimetableTheme) async throws -> String {
    let response = try await provider.request(.share(TimetableThemeRequestDTO.fromModel(theme)))
    return try response.map(TimetableThemeShareResponseDTO.self).code
  }

  public func fetch(code: String) async throws -> TimetableTheme {
    let response = try await provider.request(.fetch(code: code))
    return try response.map(TimetableThemeShareResponseDTO.self).theme.toModel()
  }
}
