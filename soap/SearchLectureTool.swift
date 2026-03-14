//
//  SearchLectureTool.swift
//  BuddyDataiOS
//
//  Created by Soongyu Kwon on 14/03/2026.
//

import FoundationModels
import BuddyDomain
import BuddyDataCore
import Moya
import Playgrounds

struct GetDepartmentTool: Tool {
  let name = "getDepartment"
  let description = "Get the list of departments."

  @Generable
  struct Arguments { }

  func call(arguments: Arguments) async throws -> String {
    return """
    - id: 9948, name: "인문사회과학부", code: "HSS"
    - id: 9947, name: "전기및전자공학부", code: "EE"
    - id: 9945, name: "전산학부", code: "CS"
    - id: 1197, name: "산업및시스템공학과", code: "IE"
    - id: 709, name: "건설및환경공학과", code: "CE"
    """
  }
}

struct SearchLectureTool: Tool {
  let name = "searchLecture"
  let description = "Search lectures for a semester by a given options."

  @Generable
  struct Arguments {
    @Guide(description: "The year of the semester to search lectures from")
    var year: Int

    @Guide(description: "The semester to search lectures from")
    var semester: Int

    @Guide(description: "Department IDs to filter lectures. Empty to search from all. DO NOT PUT RANDOM ID. JUST EMPTY THIS IF NOT SURE.")
    var departmentIDs: [Int]

    @Guide(description: "Level of lectures to filter. 100: 1st grade, 200: 2nd grade, 300: 3rd grade, 400: 4th grade. DO NOT PUT RANDOM LEVEL. EMPTY THIS IF YOU WANT TO SEARCH WIDELY.")
    var level: [Int]

    @Guide(description: "Keyword to filter lectures. EMPTY THIS IF YOU WANT TO SEARCH WIDELY.")
    var keyword: String
  }

  func call(arguments: Arguments) async throws -> String {
    let otlLectureRepository = OTLLectureRepository(provider: MoyaProvider<OTLLectureTarget>())
    let useCase = LectureUseCase(otlLectureRepository: otlLectureRepository)

    let request = LectureSearchRequest(
      year: arguments.year,
      semester: arguments.semester,
      department: arguments.departmentIDs.compactMap { String($0) },
      level: arguments.level.compactMap { String($0) },
      keyword: arguments.keyword,
      limit: 20,
      offset: 0
    )
    print("request: \(request)")
    let courseLectures = try await useCase.searchLecture(request: request)

    if courseLectures.isEmpty {
      return "No lectures found matching the search criteria."
    }

    let descriptions = courseLectures.flatMap { course in
      course.lectures.map { lecture in
        let professors = lecture.professors.map(\.name).joined(separator: ", ")
        let schedule = lecture.classes.map { cls in
          "\(cls.day) begin: (\(cls.begin)) end: (\(cls.end)) location: (\(cls.buildingName) \(cls.roomName))"
        }.joined(separator: "; ")

        return """
        - Title:\(lecture.name) (Code: \(lecture.code)) (ID: \(lecture.id))
          Type: \(lecture.type.displayName.localized()), Credit: \(lecture.credit), Section: \(lecture.section), Department: \(lecture.department.name)
          Professor: \(professors.isEmpty ? "TBA" : professors)
          Schedule: \(schedule.isEmpty ? "TBA" : schedule)
        """
      }
    }

    print(descriptions)

    return "Found \(descriptions.count) lecture(s):\n" + descriptions.joined(separator: "\n")
  }
}

@Generable
struct GenerableLecture: Codable {
  let id: Int
  let name: String
  let code: String
  let credits: Int
  let professors: [GenerableProfessor]
  let classes: [GenerableLectureClass]
}

@Generable
struct GenerableProfessor: Codable {
  let id: Int
  let name: String
}

@Generable
struct GenerableLectureClass: Codable {
  let day: String
  let begin: Int
  let end: Int
  let location: String
}

@Generable
struct GenerableTimetable: Codable {
  let lectures: [GenerableLecture]
}

#Playground {
  let session = LanguageModelSession(tools: [SearchLectureTool(), GetDepartmentTool()], instructions: "Help the user to find lectures. Get Departments first before searching for lectures.")

  let response = try await session.respond(
    to: "Suggest three lectures from Computer Science Department for year 2026 and semester 1? I am 2nd grade student. Do not suggest duplicated lectures.",
    generating: GenerableTimetable.self
  )

  print(response.content)
}
