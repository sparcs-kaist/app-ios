import CoreGraphics
import Foundation
import ImageIO

private typealias Oklab = TimetablePalette.Oklab
private typealias RGB = TimetablePalette.RGB

/// Samples a small, colour-managed thumbnail and clusters its colours in
/// OKLab, then hands the clusters to ``TimetablePalette`` to become a theme.
/// Only the resulting hex colours are kept; the photo never leaves the device.
enum TimetablePhotoPalette {
  enum GenerationError: Error {
    case unreadableImage
  }

  private static let cellCount = 8

  /// Image decoding and clustering run off the main actor, including when called
  /// from a SwiftUI task. Cancellation prevents a dismissed editor being updated.
  @concurrent
  static func generate(from data: Data) async throws -> TimetablePalette {
    try Task.checkCancellation()
    let samples = try samples(from: data)
    let clusters = merged(try dominantColors(in: samples))
    try Task.checkCancellation()

    let totalWeight = samples.reduce(0.0) { $0 + $1.weight }
    let averageLightness = samples.reduce(0.0) { $0 + $1.perceptual.x * $1.weight } / totalWeight
    let dominant = clusters[0].color.oklab
    // The colour covering most of the photo decides the appearance, with the
    // overall average only breaking near-ties: a dark wallpaper with a bright
    // sky in one corner should still read as dark.
    let isDark = 0.7 * dominant.lightness + 0.3 * averageLightness < 0.58

    // Tiny highlights should not claim a whole cell colour; a flat image still
    // produces a useful set of related shades.
    let seeds = TimetablePalette.distinctSeeds(
      from: clusters
        .filter { $0.weight / totalWeight >= 0.01 }
        .map(\.color.oklab)
    )

    return TimetablePalette.derived(
      seeds: seeds,
      dominant: dominant,
      isDark: isDark,
      cellCount: cellCount
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
    // A few more centres than there are cells: splitting the photo finely and
    // then merging what turns out to be the same colour separates its hues far
    // better than asking the clustering for exactly eight.
    while centers.count < min(10, samples.count) {
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
    return byDescendingWeight(clusters)
  }

  /// Clustering readily splits one broad area of a photo — a sky, a wall —
  /// across several centres, which leaves the largest cluster looking like a
  /// minor colour and hands the background to something the eye never noticed.
  /// Folding near-identical clusters together restores the real order of
  /// dominance, and stops two cells being given the same shade.
  private static func merged(_ clusters: [Sample]) -> [Sample] {
    var groups: [(center: SIMD3<Double>, accumulator: Accumulator)] = []
    for cluster in clusters {
      // Clusters arrive heaviest first, so a split area is folded back into the
      // largest part of itself.
      if let index = groups.indices.first(where: {
        distance(groups[$0].center, cluster.perceptual) < 0.0025
      }) {
        groups[index].accumulator.add(cluster.color, weight: cluster.weight)
      } else {
        var accumulator = Accumulator()
        accumulator.add(cluster.color, weight: cluster.weight)
        groups.append((cluster.perceptual, accumulator))
      }
    }
    return byDescendingWeight(groups.map(\.accumulator.sample))
  }

  private static func byDescendingWeight(_ samples: [Sample]) -> [Sample] {
    samples.enumerated().sorted {
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
}
