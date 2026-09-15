import Foundation
import BuddyDomain

public struct TimetableThemeRequestDTO: Encodable, Sendable {
  let name: String
  let hexColors: [String]
  let textColorHex: String
  let separatorColorHex: String?
  let backgroundColorHex: String?
  let gridLabelColorHex: String?

  static func fromModel(_ theme: TimetableTheme) -> Self {
    Self(name: theme.displayName, hexColors: theme.hexColors,
         textColorHex: theme.textColorHex, separatorColorHex: theme.separatorColorHex,
         backgroundColorHex: theme.backgroundColorHex, gridLabelColorHex: theme.gridLabelColorHex)
  }
}
