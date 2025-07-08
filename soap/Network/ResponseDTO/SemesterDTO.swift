//
//  SemesterDTO.swift
//  soap
//
//  Created by Soongyu Kwon on 04/01/2025.
//

import Foundation

struct SemesterDTO: Codable {
    let year: Int
    let semester: Int   // 1: Spring, 2: Summer, 3: Autumn, 4: Winter
    let beginning: Date?
    let end: Date?
    let courseDesciptionSubmission: Date?
    let courseRegistrationPeriodStart: Date?
    let courseRegistrationPeriodEnd: Date?
    let courseAddDropPeriodEnd: Date?
    let courseDropDeadline: Date?
    let courseEvaluationDeadline: Date?
    let gradePosting: Date?
}
