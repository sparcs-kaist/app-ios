//
//  ReportMailComposer.swift
//  soap
//
//  Created by 하정우 on 10/1/25.
//

import Foundation

struct ReportMailComposer {
  static func compose(title: String, code: String, year: Int, semester: SemesterType, professorName: String, content: String) -> String? {
    let result =  """
    mailto:otlplus@sparcs.org?subject=[Reason for Reporting] &body=
    *Please describe a reason for reporting.
    ------------------------------------------------------------------


    ------------------------------------------------------------------
    [Review Information]
    *This information has been filled automatically. Please do NOT edit.
    Lecture:  \(title) (\(code))
    Semester:  \(year) \(semester.rawValue)
    Prof.: \(professorName)
    Content:
    \(content)
    """
    .trimmingCharacters(in: .whitespaces)
    .addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)
    
    return result
  }
}
