import Foundation
import BuddyDomain

struct TimetableThemeResponseDTO: Decodable {
  let name: String
  let hexColors: [String]
  let textColorHex: String
  let separatorColorHex: String?
  let backgroundColorHex: String?
  let gridLabelColorHex: String?

  func toModel() -> TimetableTheme {
    TimetableTheme(
      id: "custom.\(UUID().uuidString)", name: name, hexColors: hexColors,
      textColorHex: textColorHex, separatorColorHex: separatorColorHex,
      backgroundColorHex: backgroundColorHex, gridLabelColorHex: gridLabelColorHex
    )
  }
}

struct TimetableThemeShareResponseDTO: Decodable {
  let code: String
  let theme: TimetableThemeResponseDTO
}
