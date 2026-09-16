import CoreGraphics
import Foundation
import ImageIO

/// Samples a small, colour-managed thumbnail and clusters its colours in OKLab.
/// Only the resulting hex colours are kept; the photo never leaves the device.
enum TimetablePhotoPalette {
  struct Palette: Equatable, Sendable {
    let colors: [String]
    let text: String
    let background: String
    let separator: String
    let gridLabel: String
  }

  enum GenerationError: Error {
    case unreadableImage
  }

  /// Image decoding and clustering run off the main actor, including when called
  /// from a SwiftUI task. Cancellation prevents a dismissed editor being updated.
  @concurrent
  static func generate(from data: Data) async throws -> Palette {
    try Task.checkCancellation()
    let samples = try samples(from: data)
    let clusters = try dominantColors(in: samples)
    try Task.checkCancellation()

    let totalWeight = samples.reduce(0) { $0 + $1.weight }
    let average = RGB(samples.reduce(SIMD3<Double>.zero) {
      $0 + $1.color.components * $1.weight
    } / totalWeight)
    let isDark = average.perceptual.x < 0.6
    let dominant = clusters[0].color
    let background = dominant.mixed(with: isDark ? .black : .white, amount: 0.92)
    let text = dominant.mixed(with: isDark ? .white : .black, amount: 0.97)

    // Tiny highlights should not occupy as much of the palette as the wallpaper's
    // main colours. A flat image still produces a useful set of related shades.
    let seeds = clusters.filter { $0.weight / totalWeight >= 0.01 }.map(\.color)
    let colors = (0..<8).map { index in
      let seed = seeds[index % seeds.count]
      let variation = Double(index) / 7
      let tone = 0.65 * seed.luminance + 0.35 * variation
      let luminance = isDark ? 0.07 + 0.11 * tone : 0.35 + 0.32 * tone
      return seed
        .withLuminance(luminance)
        .contrasting(with: text)
        .hex
    }

    return Palette(
      colors: colors,
      text: text.hex,
      background: background.hex,
      separator: background.mixed(with: text, amount: 0.22).hex,
      gridLabel: text.hex
    )
  }

  private static func samples(from data: Data) throws -> [Sample] {
    guard let source = CGImageSourceCreateWithData(data as CFData, [
      kCGImageSourceShouldCache: false
    ] as CFDictionary), let image = CGImageSourceCreateThumbnailAtIndex(source, 0, [
      kCGImageSourceCreateThumbnailFromImageAlways: true,
      kCGImageSourceCreateThumbnailWithTransform: true,
      kCGImageSourceThumbnailMaxPixelSize: 96,
      kCGImageSourceShouldCacheImmediately: true
    ] as CFDictionary), let colorSpace = CGColorSpace(name: CGColorSpace.sRGB) else {
      throw GenerationError.unreadableImage
    }

    let width = image.width
    let height = image.height
    var pixels = [UInt8](repeating: 0, count: width * height * 4)
    let rendered = pixels.withUnsafeMutableBytes { buffer -> Bool in
      guard let context = CGContext(
        data: buffer.baseAddress,
        width: width,
        height: height,
        bitsPerComponent: 8,
        bytesPerRow: width * 4,
        space: colorSpace,
        bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue | CGBitmapInfo.byteOrder32Big.rawValue
      ) else { return false }
      context.draw(image, in: CGRect(x: 0, y: 0, width: width, height: height))
      return true
    }
    guard rendered else { throw GenerationError.unreadableImage }

    // A five-bit histogram bounds clustering work and ignores transparent pixels.
    var buckets: [Int: Accumulator] = [:]
    for offset in stride(from: 0, to: pixels.count, by: 4) {
      let alpha = Double(pixels[offset + 3]) / 255
      guard alpha >= 0.5 else { continue }
      let color = RGB(SIMD3(
        min(1, Double(pixels[offset]) / 255 / alpha),
        min(1, Double(pixels[offset + 1]) / 255 / alpha),
        min(1, Double(pixels[offset + 2]) / 255 / alpha)
      ))
      let key = (Int(color.components.x * 31) << 10)
        | (Int(color.components.y * 31) << 5)
        | Int(color.components.z * 31)
      buckets[key, default: Accumulator()].add(color, weight: alpha)
    }
    guard !buckets.isEmpty else { throw GenerationError.unreadableImage }
    // Stable ordering also makes repeated imports of the same photo identical.
    return buckets.keys.sorted().map { buckets[$0]!.sample }
  }

  private static func dominantColors(in samples: [Sample]) throws -> [Sample] {
    var centers = [samples.max { $0.weight < $1.weight }!.perceptual]
    while centers.count < min(8, samples.count) {
      let next = samples.max { lhs, rhs in
        distanceToNearest(lhs.perceptual, centers) * sqrt(lhs.weight)
          < distanceToNearest(rhs.perceptual, centers) * sqrt(rhs.weight)
      }!
      guard distanceToNearest(next.perceptual, centers) > 0.0004 else { break }
      centers.append(next.perceptual)
    }

    var clusters: [Sample] = []
    for _ in 0..<12 {
      try Task.checkCancellation()
      var groups = Array(repeating: Accumulator(), count: centers.count)
      for sample in samples {
        let closest = centers.indices.min {
          distance(sample.perceptual, centers[$0]) < distance(sample.perceptual, centers[$1])
        }!
        groups[closest].add(sample.color, weight: sample.weight)
      }
      clusters = groups.filter { $0.weight > 0 }.map(\.sample)
      let updated = clusters.map(\.perceptual)
      let converged = centers.count == updated.count
        && zip(centers, updated).allSatisfy { distance($0, $1) < 0.000001 }
      centers = updated
      if converged { break }
    }
    return clusters.enumerated().sorted {
      $0.element.weight == $1.element.weight
        ? $0.offset < $1.offset
        : $0.element.weight > $1.element.weight
    }.map(\.element)
  }

  private static func distanceToNearest(_ color: SIMD3<Double>, _ centers: [SIMD3<Double>]) -> Double {
    centers.map { distance(color, $0) }.min()!
  }

  private static func distance(_ lhs: SIMD3<Double>, _ rhs: SIMD3<Double>) -> Double {
    let delta = lhs - rhs
    return delta.x * delta.x + delta.y * delta.y + delta.z * delta.z
  }

  private struct Sample {
    let color: RGB
    let weight: Double
    let perceptual: SIMD3<Double>

    init(color: RGB, weight: Double) {
      self.color = color
      self.weight = weight
      self.perceptual = color.perceptual
    }
  }

  private struct Accumulator {
    var sum = SIMD3<Double>.zero
    var weight = 0.0

    mutating func add(_ color: RGB, weight: Double) {
      sum += color.components * weight
      self.weight += weight
    }

    var sample: Sample { Sample(color: RGB(sum / weight), weight: weight) }
  }

  private struct RGB {
    let components: SIMD3<Double>

    init(_ components: SIMD3<Double>) { self.components = components }

    static let black = RGB(SIMD3(repeating: 0))
    static let white = RGB(SIMD3(repeating: 1))

    private var linear: SIMD3<Double> {
      func decode(_ value: Double) -> Double {
        value <= 0.04045 ? value / 12.92 : pow((value + 0.055) / 1.055, 2.4)
      }
      return SIMD3(decode(components.x), decode(components.y), decode(components.z))
    }

    var luminance: Double {
      let rgb = linear
      return 0.2126 * rgb.x + 0.7152 * rgb.y + 0.0722 * rgb.z
    }

    /// OKLab keeps clustering sensitive to perceptual differences, rather than
    /// giving equal weight to distances between encoded red, green and blue.
    var perceptual: SIMD3<Double> {
      let rgb = linear
      let l = cbrt(0.4122214708 * rgb.x + 0.5363325363 * rgb.y + 0.0514459929 * rgb.z)
      let m = cbrt(0.2119034982 * rgb.x + 0.6806995451 * rgb.y + 0.1073969566 * rgb.z)
      let s = cbrt(0.0883024619 * rgb.x + 0.2817188376 * rgb.y + 0.6299787005 * rgb.z)
      return SIMD3(
        0.2104542553 * l + 0.7936177850 * m - 0.0040720468 * s,
        1.9779984951 * l - 2.4285922050 * m + 0.4505937099 * s,
        0.0259040371 * l + 0.7827717662 * m - 0.8086757660 * s
      )
    }

    var hex: String {
      String(format: "%02X%02X%02X",
             Int((components.x * 255).rounded()),
             Int((components.y * 255).rounded()),
             Int((components.z * 255).rounded()))
    }

    func mixed(with other: RGB, amount: Double) -> RGB {
      RGB(components * (1 - amount) + other.components * amount)
    }

    func withLuminance(_ target: Double) -> RGB {
      let destination: RGB = luminance < target ? .white : .black
      var lower = 0.0
      var upper = 1.0
      for _ in 0..<16 {
        let amount = (lower + upper) / 2
        let candidate = mixed(with: destination, amount: amount)
        if (candidate.luminance < target) == (luminance < target) {
          lower = amount
        } else {
          upper = amount
        }
      }
      return mixed(with: destination, amount: (lower + upper) / 2)
    }

    func contrasting(with text: RGB) -> RGB {
      let ratio = (max(luminance, text.luminance) + 0.05)
        / (min(luminance, text.luminance) + 0.05)
      // A little headroom keeps contrast above 4.5 after rounding to eight bits.
      guard ratio < 4.7 else { return self }
      let target = text.luminance > 0.5
        ? (text.luminance + 0.05) / 4.7 - 0.05
        : (text.luminance + 0.05) * 4.7 - 0.05
      return withLuminance(target)
    }
  }
}
