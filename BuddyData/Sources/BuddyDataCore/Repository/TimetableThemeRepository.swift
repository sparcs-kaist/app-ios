import Foundation
import BuddyDomain
@preconcurrency import Moya

public actor TimetableThemeRepository: TimetableThemeRepositoryProtocol {
  private let provider: MoyaProvider<TimetableThemeTarget>

  public init(provider: MoyaProvider<TimetableThemeTarget>) {
    self.provider = provider
  }

  public func share(_ theme: TimetableTheme) async throws -> String {
    let response = try await provider.request(.share(TimetableThemePayload(theme)))
    return try response.map(TimetableThemeShareResponse.self).code
  }

  public func fetch(code: String) async throws -> TimetableTheme {
    guard let code = TimetableThemeShareCode.normalized(code) else {
      throw NetworkError.notFound
    }
    let response = try await provider.request(.fetch(code: code))
    return try response.map(TimetableThemeShareResponse.self).theme.importedTheme()
  }
}
