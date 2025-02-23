//
//  TimetableDTO.swift
//  soap
//
//  Created by Soongyu Kwon on 28/12/2024.
//

struct TimetableDTO: Codable {
    let id: Int
    var lectures: [LectureDTO]
}

struct LectureDTO: Codable {
    let id: Int
    let title: String
    let title_en: String
    let course: Int
    let old_code: String
    let class_no: String
    let year: Int
    let semester: Int
    let code: String
    let department: Int
    let department_code: String
    let department_name: String
    let department_name_en: String
    let type: String
    let type_en: String
    let limit: Int
    let num_people: Int
    let is_english: Bool
    let credit: Int
    let credit_au: Int
    let common_title: String
    let common_title_en: String
    let class_title: String
    let class_title_en: String
    let review_total_weight: Double
    let grade: Double
    let load: Double
    let speech: Double
    let professors: [ProfessorDTO]
    let classtimes: [ClasstimeDTO]
    let examtimes: [ExamtimeDTO]?
}

struct ProfessorDTO: Codable {
    let name: String
    let name_en: String
    let professor_id: Int
    let review_total_weight: Double
}

struct ClasstimeDTO: Codable {
    let building_code: String
    let classroom: String
    let classroom_en: String
    let classroom_short: String
    let classroom_short_en: String
    let room_name: String
    let day: Int
    let begin: Int
    let end: Int
}

struct ExamtimeDTO: Codable {
    let str: String
    let str_en: String
    let day: Int
    let begin: Int
    let end: Int
}
