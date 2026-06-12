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
	let instructions = """
		You are an expert academic advisor and schedule coordinator. Your goal is to help the user build their ideal university timetable for the specified semester.
		
		CRITICAL BEHAVIOR GUIDELINES:
		1. Tool Usage Workflow:
		 - If the user asks for lectures in a specific department, you MUST call `getDepartment` first to find the correct `id`. Do NOT guess or hallucinate department IDs.
		 - Use the retrieved IDs, along with the user's requested year, semester, and other filters, to call `searchLecture`.
		 - Never use random or placeholder values for `departmentIDs` or `level` in `searchLecture`. If you are unsure or the user didn't specify, leave them empty.
		
		2. Timetable Generation Rules:
		 - Only include lectures in the timetable that were explicitly returned by the `searchLecture` tool.
		 - Ensure there are NO schedule conflicts (overlapping days and times) in the final timetable unless the user explicitly allows it.
		 - Map the tool's output data fields precisely to the `GenerableTimetable` schema structure.
		"""
	let session = LanguageModelSession(model: SystemLanguageModel(), tools: [SearchLectureTool(), GetDepartmentTool()], instructions: instructions)
	
	let prompt = """
		Please generate a valid, conflict-free timetable for the following semester and preferences:
		
		### Semester Information
		- Year: 2026
		- Semester: 1
		
		### User Preferences & Constraints
		- Target Departments: 전산학부 (CS)" and “건설및환경공학과 (CEE)"
		- Preferred Class Levels: "200 and 300 level courses"
		- Keywords/Specific Courses: “None”
		- Credit Limits: Minimum 12 credits, maximum 18 credits"
		
		### Step-by-Step Execution Plan:
		1. Look up the department IDs using `getDepartment` if specific departments are requested.
		2. Search for relevant lectures using `searchLecture` using the correct year, semester, and filtered IDs.
		3. Select a combination of lectures that fulfill the credit requirements without any time overlaps.
		4. Construct and return the final `GenerableTimetable` JSON object matching the requested schema.
		"""
	let response = try await session.respond(to: prompt, generating: GenerableTimetable.self)

  print(response.content)
}
