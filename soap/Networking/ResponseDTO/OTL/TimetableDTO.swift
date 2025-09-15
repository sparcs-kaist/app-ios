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
