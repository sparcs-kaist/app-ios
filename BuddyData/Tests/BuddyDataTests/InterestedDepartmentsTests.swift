import Testing
import Foundation
import Moya
import BuddyDomain
@testable import BuddyDataCore

@Suite("Interested departments")
struct InterestedDepartmentsTests {
  // `mail` rather than `email`, and a null degree, are what the server actually sends.
  private let userInfo = #"""
  {"id":7,"name":"Buddy Kim","mail":"buddy@kaist.ac.kr","studentNumber":20250001,"degree":null,
   "majorDepartments":[{"id":9945,"name":"전산학부","name_en":"School of Computing","code":"CS"}],
   "interestedDepartments":[{"id":623,"name":"물리학과","name_en":"Physics","code":"PH"}]}
  """#

  @Test func decodesUserInfoWithInterestedDepartments() async throws {
    let stub = UserAPIStub { _ in (200, userInfo) }

    let user = try await stub.repository.fetchUser()

    #expect(user.id == 7)
    #expect(user.email == "buddy@kaist.ac.kr")
    #expect(user.degree == "")
    #expect(user.majorDepartments.map(\.id) == [9945])
    #expect(user.interestedDepartments.map(\.id) == [623])
  }

  @Test func updateReplacesInterestedDepartmentsOfTheSignedInUser() async throws {
    let stub = UserAPIStub { target in
      if case .fetchUserInfo = target { (200, userInfo) } else { (200, "") }
    }
    let storage = UserStorage()
    let useCase = UserUseCase(
      taxiUserRepository: nil,
      feedUserRepository: nil,
      araUserRepository: nil,
      otlUserRepository: stub.repository,
      userStorage: storage
    )

    try await useCase.updateInterestedDepartments(departmentIDs: [623, 9945])

    // The user is looked up first for its id, and refreshed afterwards so the app sees the change.
    #expect(stub.targets.map(\.path) == [
      "/api/v2/users/info",
      "/api/v2/users/7/interested-departments",
      "/api/v2/users/info"
    ])
    let update = stub.targets[1]
    #expect(update.method == .put)
    guard case .requestParameters(let payload, let encoding) = update.task else {
      Issue.record("Expected a JSON payload")
      return
    }
    #expect(encoding is JSONEncoding)
    #expect(payload["interestedDepartmentIds"] as? [Int] == [623, 9945])
    #expect(payload.count == 1)
    #expect(await useCase.otlUser?.interestedDepartments.map(\.id) == [623])
  }
}

private final class UserAPIStub: @unchecked Sendable {
  private let lock = NSLock()
  private var recorded: [OTLUserTarget] = []
  let response: @Sendable (OTLUserTarget) -> (Int, String)
  var targets: [OTLUserTarget] { lock.withLock { recorded } }

  init(response: @escaping @Sendable (OTLUserTarget) -> (Int, String)) { self.response = response }

  var repository: OTLUserRepository {
    let provider = MoyaProvider<OTLUserTarget>(endpointClosure: { target in
      self.lock.withLock { self.recorded.append(target) }
      let (status, body) = self.response(target)
      return Endpoint(url: target.baseURL.absoluteString + target.path,
        sampleResponseClosure: { .networkResponse(status, Data(body.utf8)) },
        method: target.method, task: target.task, httpHeaderFields: target.headers)
    }, stubClosure: MoyaProvider.immediatelyStub)
    return OTLUserRepository(provider: provider)
  }
}
