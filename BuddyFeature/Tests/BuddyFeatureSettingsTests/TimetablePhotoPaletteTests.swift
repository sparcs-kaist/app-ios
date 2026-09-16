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
    #expect(luminance(dark.background) < 0.05)
    #expect(luminance(dark.text) > 0.9)
    #expect(luminance(light.background) > 0.9)
    #expect(luminance(light.text) < 0.05)
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
    let context = try #require(CGContext(
      data: nil, width: width, height: height, bitsPerComponent: 8, bytesPerRow: width * 4,
      space: CGColorSpace(name: CGColorSpace.sRGB)!,
      bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
    ))
    for (index, hex) in colors.enumerated() {
      let color = rgb(hex)
      context.setFillColor(CGColor(red: color.x, green: color.y, blue: color.z, alpha: 1))
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

  private func contrast(_ first: String, _ second: String) -> Double {
    let values = [luminance(first), luminance(second)].sorted()
    return (values[1] + 0.05) / (values[0] + 0.05)
  }
}
