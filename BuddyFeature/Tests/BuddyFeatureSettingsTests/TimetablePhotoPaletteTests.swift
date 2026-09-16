import CoreGraphics
import Foundation
import ImageIO
import Testing
import UniformTypeIdentifiers
@testable import BuddyFeatureSettings

struct TimetablePhotoPaletteTests {
  @Test(arguments: [
    ["102033", "304C62", "68424C", "273F35"],
    ["FFE3BB", "C3DDBA", "AFC9E8", "E4B4C8"],
    ["FF0000", "00FF00", "0000FF", "FFFF00"],
    ["000000"], ["FFFFFF"], ["777777"]
  ])
  func generatesReadableCompletePalette(hexColors: [String]) async throws {
    let palette = try await TimetablePhotoPalette.generate(from: photo(hexColors))
    #expect(palette.colors.count == 8)
    #expect(Set(palette.colors).count >= 4)
    for hex in palette.colors + [palette.text, palette.background, palette.separator, palette.gridLabel] {
      #expect(hex.count == 6 && UInt32(hex, radix: 16) != nil)
    }
    for color in palette.colors {
      #expect(contrast(color, palette.text) >= 4.5)
      #expect(contrast(color, palette.background) >= 1.2)
    }
    #expect(contrast(palette.background, palette.gridLabel) >= 4.5)
    #expect(palette.separator != palette.background)
  }

  @Test func keepsTheWallpapersLightOrDarkAppearance() async throws {
    let dark = try await TimetablePhotoPalette.generate(from: photo(["182B43", "283F5C"]))
    let light = try await TimetablePhotoPalette.generate(from: photo(["FFEEDD", "E6DACB"]))
    #expect(luminance(dark.background) < 0.06)
    #expect(luminance(dark.text) > 0.85)
    #expect(luminance(light.background) > 0.75)
    #expect(luminance(light.text) < 0.05)
  }

  /// The background has to look like the colour the photo is mostly made of,
  /// or a wallpaper and the grid on top of it read as two unrelated pictures.
  @Test func backgroundKeepsTheDominantColour() async throws {
    // Three quarters teal, one quarter rust: the lighter, more saturated accent
    // must not talk the background out of being teal.
    let palette = try await TimetablePhotoPalette.generate(
      from: photo(["1E5A5A", "1E5A5A", "1E5A5A", "9A3B2C"])
    )
    let dominant = oklch("1E5A5A")
    let background = oklch(palette.background)
    #expect(hueDistance(background, dominant) < 0.2)
    #expect(background.chroma > 0.02)
    #expect(abs(background.lightness - dominant.lightness) < 0.25)
  }

  /// Cells are variations on the photo's colours, not a new palette that merely
  /// meets contrast.
  @Test func cellColorsStayNearThePhotosHues() async throws {
    let sources = ["2F6DB5", "B5502F", "3F8F3F"]
    let palette = try await TimetablePhotoPalette.generate(from: photo(sources))
    let hues = sources.map(oklch)
    for color in palette.colors.map(oklch) where color.chroma > 0.02 {
      #expect(hues.contains { hueDistance(color, $0) < 0.35 })
    }
    // Being close to the photo cannot mean being invisible on top of it.
    for color in palette.colors {
      #expect(contrast(color, palette.background) >= 1.2)
    }
  }

  @Test func retainsDistinctPhotoHues() async throws {
    let palette = try await TimetablePhotoPalette.generate(from: photo(["993333", "336633", "333399"]))
    let channels = palette.colors.map(rgb)
    #expect(channels.contains { $0.x > $0.y * 1.3 && $0.x > $0.z * 1.3 })
    #expect(channels.contains { $0.y > $0.x * 1.3 && $0.y > $0.z * 1.3 })
    #expect(channels.contains { $0.z > $0.x * 1.3 && $0.z > $0.y * 1.3 })
  }

  @Test func repeatedGenerationIsDeterministic() async throws {
    let data = try photo(["9D654D", "38605C", "D8B888"])
    let first = try await TimetablePhotoPalette.generate(from: data)
    let second = try await TimetablePhotoPalette.generate(from: data)
    #expect(first == second)
  }

  @Test func supportsOnePixelAndTransparentMargins() async throws {
    let tiny = try await TimetablePhotoPalette.generate(from: photo(["315D78"], width: 1, height: 1))
    let padded = try await TimetablePhotoPalette.generate(from: photo(["315D78"], transparentMargin: true))
    #expect(tiny == padded)
  }

  @Test func rejectsUnreadableOrFullyTransparentImages() async throws {
    for data in [Data(), Data("not a photo".utf8), try photo([], width: 1, height: 1)] {
      await #expect(throws: TimetablePhotoPalette.GenerationError.unreadableImage) {
        try await TimetablePhotoPalette.generate(from: data)
      }
    }
  }

  @Test func respectsCancellation() async throws {
    let data = try photo(["123456"])
    let task = Task {
      withUnsafeCurrentTask { $0?.cancel() }
      return try await TimetablePhotoPalette.generate(from: data)
    }
    await #expect(throws: CancellationError.self) { try await task.value }
  }

  private func photo(
    _ colors: [String], width: Int = 96, height: Int = 64, transparentMargin: Bool = false
  ) throws -> Data {
    let space = CGColorSpace(name: CGColorSpace.sRGB)!
    let context = try #require(CGContext(
      data: nil, width: width, height: height, bitsPerComponent: 8, bytesPerRow: width * 4,
      space: space,
      bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
    ))
    for (index, hex) in colors.enumerated() {
      let color = rgb(hex)
      // Tagged sRGB, not `CGColor(red:green:blue:alpha:)`: that one is generic
      // RGB, and converting its 1.8 gamma into the context would hand the
      // palette lighter colours than the ones these tests name.
      context.setFillColor(CGColor(colorSpace: space, components: [color.x, color.y, color.z, 1])!)
      context.fill(CGRect(
        x: index * width / colors.count,
        y: transparentMargin ? height / 4 : 0,
        width: width / colors.count,
        height: transparentMargin ? height / 2 : height
      ))
    }
    let image = try #require(context.makeImage())
    let data = NSMutableData()
    let destination = try #require(CGImageDestinationCreateWithData(data, UTType.png.identifier as CFString, 1, nil))
    CGImageDestinationAddImage(destination, image, nil)
    #expect(CGImageDestinationFinalize(destination))
    return data as Data
  }

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
