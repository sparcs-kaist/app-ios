//
//  TimetableColorPalette.swift
//  soap
//
//  Created by Soongyu Kwon on 28/12/2024.
//
import SwiftUI

struct TimetableColorPalette {
    static var palettes: [ColorPalette] {
        [
            ColorPalette(
                name: "Default",
                hexColors: [
                    "C3BA0A",
                    "E34B6C",
                    "307878",
                    "B4C94B",
                    "1D8253",
                    "FA9C3E",
                    "F06E70",
                    "233575",
                    "63A763",
                    "D28DD9",
                    "68C2D9",
                    "DD615D",
                    "8F64C5",
                    "F26549",
                    "67929E",
                    "6476C5"
                ],
                textColor: .white
            ),
            ColorPalette(
                name: "Legacy",
                hexColors: [
                    "F2CECE",
                    "F4B3AE",
                    "F2BCA0",
                    "F0D3AB",
                    "F1E1A9",
                    "F4F2B3",
                    "DBF4BE",
                    "BEEDD7",
                    "B7E2DE",
                    "C9EAF4",
                    "B4D3ED",
                    "B9C5ED",
                    "CCC6ED",
                    "D8C1F0",
                    "EBCAEF",
                    "F4BADB"
                ],
                textColor: .black
            ),
            ColorPalette(
                name: "Olive",
                hexColors: [
                    "0A0B06",
                    "1E2528",
                    "151518",
                    "1E1D19",
                    "1E1E1E",
                    "292929",
                    "575760",
                    "6C6C70",
                    "C4C3C9",
                    "80978F",
                    "3E3B34",
                    "666652",
                    "7B8962",
                    "344620",
                    "70877F",
                    "233A6C"
                ],
                textColor: Color(hex: "FFFDE9")
            )
        ]
    }
}

struct ColorPalette: Identifiable {
    let id = UUID()
    let name: String
    let hexColors: [String]
    let textColor: Color
    
    var colors: [Color] {
        hexColors.map { Color(hex: $0) }
    }
}
