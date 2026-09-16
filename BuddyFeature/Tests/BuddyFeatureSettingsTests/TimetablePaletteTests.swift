import Foundation
import Testing
import BuddyDomain
@testable import BuddyFeatureSettings

/// A described theme is the model's key colours run through the photo path, so
/// what is worth testing here is the handover: that the colours it named get
/// there intact, and that the theme which comes back out is complete and
/// readable at sixteen blocks rather than the photo path's eight.
struct TimetablePaletteTests {
  private static let cellCount = 16

  private func brief(
    appearance: TimetableThemeBrief.Appearance = .dark,
    colours: [String]
  ) -> TimetableThemeBrief {
    TimetableThemeBrief(
      name: "Test",
      appearance: appearance,
      anchorHexColors: colours
    )
  }

  // MARK: - The colours it named are the theme

  /// A club of two colours: both have to be in the grid, in variations of
  /// each, which is the case that has been wrong throughout.
  @Test func buildsFromBothColoursOfATwoColourDescription() throws {
    let palette = try #require(TimetablePalette.derived(
      from: brief(colours: ["C8102E", "1B7A3D", "A00C24", "145E2F"]),
      cellCount: Self.cellCount
    ))

    let red = oklch("C8102E")
    let green = oklch("1B7A3D")
    let cells = palette.colors.map(oklch)
    #expect(cells.contains { hueDistance($0, red) < 0.4 }, "no red block")
    #expect(cells.contains { hueDistance($0, green) < 0.4 }, "no green block")
    // And nothing from outside what it named.
    for cell in cells where cell.chroma > 0.02 {
      #expect(
        hueDistance(cell, red) < 0.6 || hueDistance(cell, green) < 0.6,
        "invented a colour the description did not have"
      )
    }
  }

  /// One colour named means shades of it and nothing else.
  @Test func staysWithinOneColourWhenThatIsAllItNamed() throws {
    let palette = try #require(TimetablePalette.derived(
      from: brief(appearance: .light, colours: ["4C9A2A", "7FD67A", "2E6B1F"]),
      cellCount: Self.cellCount
    ))
    for cell in palette.colors {
      let channels = rgb(cell)
      #expect(channels.y > channels.x, "\(cell) is not green")
      #expect(channels.y > channels.z, "\(cell) is not green")
    }
  }

  /// A mood has no colours of its own, so the model names several and all of
  /// them should reach the grid.
  @Test func keepsTheSpreadOfAManyColouredDescription() throws {
    let named = ["E63946", "F3722C", "F9C74F", "43AA8B", "277DA1", "7209B7"]
    let palette = try #require(TimetablePalette.derived(
      from: brief(colours: named),
      cellCount: Self.cellCount
    ))
    let wanted = named.map(oklch)
    var reached = 0
    for hue in wanted where palette.colors.map(oklch).contains(where: { hueDistance($0, hue) < 0.3 }) {
      reached += 1
    }
    #expect(reached >= 5, "only \(reached) of the six colours reached the grid")
  }

  @Test func theGridTakesItsTintFromTheFirstColour() throws {
    let palette = try #require(TimetablePalette.derived(
      from: brief(colours: ["1E5A5A", "9A3B2C"]),
      cellCount: Self.cellCount
    ))
    #expect(hueDistance(oklch(palette.background), oklch("1E5A5A")) < 0.3)
  }

  @Test func honoursTheRequestedAppearance() throws {
    let colours = ["4C7A8C", "D9A55B", "2E3A46"]
    let dark = try #require(TimetablePalette.derived(
      from: brief(appearance: .dark, colours: colours),
      cellCount: Self.cellCount
    ))
    let light = try #require(TimetablePalette.derived(
      from: brief(appearance: .light, colours: colours),
      cellCount: Self.cellCount
    ))
    #expect(luminance(dark.background) < luminance(light.background))
    #expect(oklch(dark.background).lightness < 0.35)
    #expect(oklch(light.background).lightness > 0.8)
  }

  // MARK: - Complete and readable at sixteen

  @Test(arguments: [
    ["C8102E", "1B7A3D", "A00C24", "145E2F"],
    ["4C9A2A", "7FD67A", "2E6B1F"],
    ["E63946", "F3722C", "F9C74F", "43AA8B", "277DA1", "7209B7"],
    ["0B0B0F", "2D1B4E"],
    ["FFE066"],
    ["777777", "808080"]
  ])
  func fillsEverySlotReadably(colours: [String]) throws {
    for appearance in [TimetableThemeBrief.Appearance.dark, .light] {
      let palette = try #require(TimetablePalette.derived(
        from: brief(appearance: appearance, colours: colours),
        cellCount: Self.cellCount
      ))

      #expect(palette.colors.count == Self.cellCount)
      for hex in palette.colors + [palette.text, palette.background, palette.separator, palette.gridLabel] {
        #expect(hex.count == 6 && UInt32(hex, radix: 16) != nil)
      }
      for cell in palette.colors {
        #expect(contrast(cell, palette.text) >= 4.5, "\(cell): text is not readable")
        #expect(contrast(cell, palette.background) >= 1.2, "\(cell) sinks into the grid")
      }
      #expect(contrast(palette.background, palette.gridLabel) >= 4.5)
      #expect(palette.separator != palette.background)
    }
  }

  /// Sixteen blocks out of a handful of colours is more fanning out than the
  /// photo path does at eight, so this is the number worth watching: shades so
  /// close together that two courses look alike are what the whole exercise
  /// has been trying to avoid.
  @Test(arguments: [
    ["C8102E", "1B7A3D", "A00C24", "145E2F"],
    ["4C9A2A", "7FD67A", "2E6B1F"],
    ["E63946", "F3722C", "F9C74F", "43AA8B", "277DA1", "7209B7"],
    ["FFE066"]
  ])
  func tellsEveryBlockApart(colours: [String]) throws {
    for appearance in [TimetableThemeBrief.Appearance.dark, .light] {
      let palette = try #require(TimetablePalette.derived(
        from: brief(appearance: appearance, colours: colours),
        cellCount: Self.cellCount
      ))
      #expect(
        Set(palette.colors).count == Self.cellCount,
        "\(colours.count) colours/\(appearance): a block colour repeats"
      )
    }
  }

  // MARK: - Half-written answers

  @Test(arguments: [
    (["#C8102E", "c8102e", " C8102E "], 1),
    (["C81", "1B7A3D"], 2),
    (["C8102E", "C8", "", "GGGGGG", "C8102E00"], 1),
    (["C8102E", "1B7A3D", "C8102E"], 2)
  ])
  func dropsWhatIsNotAColourAndFoldsWhatRepeats(colours: [String], expected: Int) {
    #expect(TimetablePalette.seeds(fromHexColors: colours).count == expected)
  }

  /// `#ABC` is the same colour as `#AABBCC`, so the shorthand has to expand
  /// rather than be read as three channels of one digit.
  @Test func expandsThreeDigitShorthand() {
    #expect(
      TimetablePalette.seeds(fromHexColors: ["1A4"]).first?.hue
        == TimetablePalette.seeds(fromHexColors: ["11AA44"]).first?.hue
    )
  }

  @Test func hasNothingToShowUntilThereIsAnAppearanceAndAColour() {
    #expect(TimetablePalette.derived(
      from: TimetableThemeBrief(name: "Half written"),
      cellCount: Self.cellCount
    ) == nil)
    #expect(TimetablePalette.derived(
      from: brief(colours: []),
      cellCount: Self.cellCount
    ) == nil)
    // A colour the model is halfway through writing isn't one yet.
    #expect(TimetablePalette.derived(
      from: brief(colours: ["C810"]),
      cellCount: Self.cellCount
    ) == nil)
  }

  /// A palette is rebuilt on every snapshot while the brief streams in, so it
  /// has to come out the same each time or the preview would flicker.
  @Test func rebuildingTheSameBriefGivesTheSamePalette() {
    let request = brief(colours: ["C8102E", "1B7A3D"])
    let first = TimetablePalette.derived(from: request, cellCount: Self.cellCount)
    let second = TimetablePalette.derived(from: request, cellCount: Self.cellCount)
    #expect(first == second)
  }

  // MARK: - Helpers

  private func rgb(_ hex: String) -> SIMD3<Double> {
    let value = UInt32(hex, radix: 16)!
    return SIMD3(Double((value >> 16) & 255), Double((value >> 8) & 255), Double(value & 255)) / 255
  }

  private func luminance(_ hex: String) -> Double {
    let color = rgb(hex)
    func linear(_ channel: Double) -> Double {
      channel <= 0.04045 ? channel / 12.92 : pow((channel + 0.055) / 1.055, 2.4)
    }
    return 0.2126 * linear(color.x) + 0.7152 * linear(color.y) + 0.0722 * linear(color.z)
  }

  private struct Oklch {
    let lightness: Double
    let chroma: Double
    let hue: Double
  }

  private func oklch(_ hex: String) -> Oklch {
    let color = rgb(hex)
    func linear(_ channel: Double) -> Double {
      channel <= 0.04045 ? channel / 12.92 : pow((channel + 0.055) / 1.055, 2.4)
    }
    let value = SIMD3(linear(color.x), linear(color.y), linear(color.z))
    let l = cbrt(0.4122214708 * value.x + 0.5363325363 * value.y + 0.0514459929 * value.z)
    let m = cbrt(0.2119034982 * value.x + 0.6806995451 * value.y + 0.1073969566 * value.z)
    let s = cbrt(0.0883024619 * value.x + 0.2817188376 * value.y + 0.6299787005 * value.z)
    let a = 1.9779984951 * l - 2.4285922050 * m + 0.4505937099 * s
    let b = 0.0259040371 * l + 0.7827717662 * m - 0.8086757660 * s
    return Oklch(
      lightness: 0.2104542553 * l + 0.7936177850 * m - 0.0040720468 * s,
      chroma: (a * a + b * b).squareRoot(),
      hue: atan2(b, a)
    )
  }

  private func hueDistance(_ first: Oklch, _ second: Oklch) -> Double {
    let delta = abs(first.hue - second.hue)
    return min(delta, 2 * .pi - delta)
  }

  private func contrast(_ first: String, _ second: String) -> Double {
    let values = [luminance(first), luminance(second)].sorted()
    return (values[1] + 0.05) / (values[0] + 0.05)
  }
}
