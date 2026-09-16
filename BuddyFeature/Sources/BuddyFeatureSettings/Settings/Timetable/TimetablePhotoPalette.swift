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

  /// Text clears the surface behind it by this ratio: a little above the 4.5:1
  /// minimum, so rounding to eight bits per channel cannot drop it below.
  private static let readableContrast = 4.7
  private static let cellCount = 8

  /// Image decoding and clustering run off the main actor, including when called
  /// from a SwiftUI task. Cancellation prevents a dismissed editor being updated.
  @concurrent
  static func generate(from data: Data) async throws -> Palette {
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

    // The background *is* the dominant colour, taken only as far towards black
    // or white as legible text needs. Mixing it almost entirely into black —
    // the naive way to darken — throws away the very colour it should echo, so
    // the grid stops looking like it came from the photo behind it.
    let background = Oklab(
      lightness: isDark
        ? min(max(dominant.lightness * 0.62, 0.10), 0.30)
        : min(max(1 - (1 - dominant.lightness) * 0.55, 0.84), 0.96),
      chroma: isDark
        ? min(dominant.chroma * 0.9, 0.085)
        : min(dominant.chroma * 0.75, 0.055),
      hue: dominant.hue
    )
    // Course titles stay near-white or near-black; the trace of the dominant
    // hue keeps them from looking foreign on top of the coloured cells.
    let text = Oklab(
      lightness: isDark ? 0.985 : 0.16,
      chroma: min(dominant.chroma * 0.25, 0.02),
      hue: dominant.hue
    )
    // A hairline that reads as an edge of the background rather than a colour
    // of its own.
    let separator = Oklab(
      lightness: isDark
        ? min(background.lightness + 0.13, 0.55)
        : max(background.lightness - 0.11, 0.45),
      chroma: background.chroma,
      hue: background.hue
    )
    // Day and hour labels sit directly on the background, so they are tinted
    // rather than pure white or black, then pushed back until they clear it.
    let gridLabel = Oklab(
      lightness: isDark ? 0.84 : 0.36,
      chroma: min(dominant.chroma * 0.5, 0.05),
      hue: dominant.hue
    ).contrasting(with: background.rgb, darker: !isDark)

    // Tiny highlights should not claim a whole cell colour; a flat image still
    // produces a useful set of related shades below.
    let seeds = seedColors(from: clusters.filter { $0.weight / totalWeight >= 0.01 })

    return Palette(
      colors: cellColors(seeds: seeds, background: background, text: text, isDark: isDark),
      text: text.rgb.hex,
      background: background.rgb.hex,
      separator: separator.rgb.hex,
      gridLabel: gridLabel.rgb.hex
    )
  }

  /// Cell colours are the photo's own clusters — same hues, same order of
  /// dominance — placed in a lightness band that sits clear of both the
  /// background and the text. With fewer clusters than cells, the later cells
  /// repeat those hues as lighter and darker variants instead of inventing new
  /// ones, which is what keeps the palette reading as one photograph.
  private static func cellColors(
    seeds: [Oklab],
    background: Oklab,
    text: Oklab,
    isDark: Bool
  ) -> [String] {
    // The far edge of the band is where a neutral surface would just meet the
    // readable contrast against the text; the near edge keeps the cells from
    // sinking into the background.
    let limit = isDark
      ? (text.rgb.luminance + 0.05) / readableContrast - 0.05
      : (text.rgb.luminance + 0.05) * readableContrast - 0.05
    // For a grey, OKLab lightness is the cube root of relative luminance.
    let edge = cbrt(min(max(limit, 0), 1))
    let near = isDark
      ? max(background.lightness + 0.14, 0.30)
      : min(background.lightness - 0.11, 0.88)
    let far = isDark ? max(edge, near + 0.06) : min(edge, near - 0.06)
    let band = isDark ? near...far : far...near

    // Clusters are spaced evenly across the band by their order of lightness
    // rather than by the distance between them: the band is far narrower than a
    // photo's range of lightness, and squeezing the real spacing into it leaves
    // two clusters that differed only in lightness looking like one colour.
    let ranks = ranks(of: seeds)
    let rounds = (cellCount + seeds.count - 1) / seeds.count
    let offsets = variations(rounds)
    // A pale cluster stays the paler cell, so the palette keeps the order the
    // eye read in the photo. The more passes it takes to fill eight cells, the
    // less that order is worth holding on to: cells drawn from two hues have to
    // use the whole band to stay apart, while eight clusters can each keep the
    // place they had.
    let anchor = min(0.8, 1 / Double(rounds))

    return (0..<cellCount).map { index in
      let seed = seeds[index % seeds.count]
      let round = index / seeds.count
      let rank = ranks[index % seeds.count]
      let tone = min(max(anchor * rank + (1 - anchor) * (0.5 + offsets[round] * 0.95), 0), 1)
      // Averaging a cluster costs it some chroma, and the boost puts that back.
      // Near-neutral clusters are left alone: their hue is only noise, and
      // saturating it would invent a colour the photo never had.
      let chroma = seed.chroma < 0.012
        ? seed.chroma
        : min(seed.chroma * max(1.15 - 0.1 * Double(round), 0.7), 0.16)
      return Oklab(
        lightness: band.lowerBound + (band.upperBound - band.lowerBound) * tone,
        chroma: chroma,
        // Later passes lean a few degrees off the cluster's hue — an analogous
        // shade, never a new colour — which is what keeps a photo of one blue
        // sky from yielding eight cells nobody can tell apart. A near-neutral
        // cluster has no hue to lean on, and stays neutral.
        hue: seed.hue + 0.5 * offsets[round]
      )
      .contrasting(with: text.rgb, darker: isDark)
      .rgb
      .hex
    }
  }

  /// A cell keeps its cluster's hue and chroma but is given the band's
  /// lightness, so two clusters that share hue and chroma arrive as the same
  /// cell however far apart the photo held them — a sky's dark and pale blues
  /// otherwise fill half the palette with one colour. Seeds are chosen for
  /// distinctness in hue and chroma alone, heaviest first, and the band's own
  /// variations then fan each one into light and dark cells deliberately.
  private static func seedColors(from clusters: [Sample]) -> [Oklab] {
    var seeds: [Oklab] = []
    for cluster in clusters {
      let color = cluster.color.oklab
      let isDistinct = seeds.allSatisfy { seed in
        let delta = SIMD2(seed.a - color.a, seed.b - color.b)
        return (delta.x * delta.x + delta.y * delta.y).squareRoot() >= 0.03
      }
      if isDistinct { seeds.append(color) }
    }
    return seeds
  }

  /// Each cluster's place in the order of lightness, from 0 for the darkest to
  /// 1 for the lightest, with a single cluster sitting in the middle.
  private static func ranks(of seeds: [Oklab]) -> [Double] {
    guard seeds.count > 1 else { return [0.5] }
    let order = seeds.indices.sorted {
      seeds[$0].lightness == seeds[$1].lightness
        ? $0 < $1
        : seeds[$0].lightness < seeds[$1].lightness
    }
    var ranks = [Double](repeating: 0, count: seeds.count)
    for (position, index) in order.enumerated() {
      ranks[index] = Double(position) / Double(seeds.count - 1)
    }
    return ranks
  }

  /// Evenly spaced lightness offsets ordered from the centre outwards, so the
  /// first pass over the clusters uses them close to the lightness the photo
  /// had, and later passes fan out around it.
  private static func variations(_ count: Int) -> [Double] {
    guard count > 1 else { return [0] }
    return (0..<count)
      .map { -0.5 + Double($0) / Double(count - 1) }
      .sorted { abs($0) == abs($1) ? $0 > $1 : abs($0) < abs($1) }
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

  /// OKLab, addressed as lightness, chroma and hue: the form that lets a colour
  /// be made readable by moving its lightness alone, instead of mixing it into
  /// black or white and washing the photo's colour out of it.
  private struct Oklab {
    let lightness: Double
    let a: Double
    let b: Double

    init(lightness: Double, a: Double, b: Double) {
      self.lightness = lightness
      self.a = a
      self.b = b
    }

    init(lightness: Double, chroma: Double, hue: Double) {
      self.init(lightness: lightness, a: cos(hue) * chroma, b: sin(hue) * chroma)
    }

    var chroma: Double { (a * a + b * b).squareRoot() }
    var hue: Double { atan2(b, a) }

    /// OKLab describes colours sRGB cannot show, so chroma — never lightness or
    /// hue — is given up until the colour fits. Clipping the channels instead
    /// would shift the hue, and a family of shades would stop matching.
    var rgb: RGB {
      if let displayable = RGB(self) { return displayable }
      var lower = 0.0
      var upper = 1.0
      for _ in 0..<12 {
        let amount = (lower + upper) / 2
        if RGB(scalingChroma(amount)) != nil { lower = amount } else { upper = amount }
      }
      let reduced = scalingChroma(lower)
      return RGB(reduced) ?? RGB(clamping: reduced)
    }

    private func scalingChroma(_ amount: Double) -> Oklab {
      Oklab(lightness: lightness, a: a * amount, b: b * amount)
    }

    private func withLightness(_ lightness: Double) -> Oklab {
      Oklab(lightness: lightness, a: a, b: b)
    }

    /// Lifts or lowers the lightness — and nothing else — until the colour
    /// clears `other` by the readable ratio, so meeting contrast never costs a
    /// cell its hue.
    func contrasting(with other: RGB, darker: Bool) -> Oklab {
      let reference = other.luminance
      let target = darker
        ? (reference + 0.05) / readableContrast - 0.05
        : (reference + 0.05) * readableContrast - 0.05
      let luminance = rgb.luminance
      guard darker ? luminance > target : luminance < target else { return self }
      return withLuminance(min(max(target, 0), 1))
    }

    /// Luminance rises with lightness at a fixed hue and chroma, so a bisection
    /// lands on the requested luminance without touching either.
    private func withLuminance(_ target: Double) -> Oklab {
      var lower = 0.0
      var upper = 1.0
      for _ in 0..<20 {
        let candidate = (lower + upper) / 2
        if withLightness(candidate).rgb.luminance < target {
          lower = candidate
        } else {
          upper = candidate
        }
      }
      return withLightness((lower + upper) / 2)
    }
  }

  private struct RGB {
    let components: SIMD3<Double>

    init(_ components: SIMD3<Double>) { self.components = components }

    /// `nil` when the colour falls outside sRGB, so the caller can bring it back
    /// into gamut on its own terms.
    init?(_ color: Oklab) {
      let linear = RGB.linear(from: color)
      guard linear.min() >= -0.0005, linear.max() <= 1.0005 else { return nil }
      self.init(clamping: color)
    }

    init(clamping color: Oklab) {
      let linear = RGB.linear(from: color)
        .clamped(lowerBound: .zero, upperBound: SIMD3(repeating: 1))
      func encode(_ value: Double) -> Double {
        value <= 0.0031308 ? value * 12.92 : 1.055 * pow(value, 1 / 2.4) - 0.055
      }
      self.init(SIMD3(encode(linear.x), encode(linear.y), encode(linear.z)))
    }

    private static func linear(from color: Oklab) -> SIMD3<Double> {
      func cube(_ value: Double) -> Double { value * value * value }
      let l = cube(color.lightness + 0.3963377774 * color.a + 0.2158037573 * color.b)
      let m = cube(color.lightness - 0.1055613458 * color.a - 0.0638541728 * color.b)
      let s = cube(color.lightness - 0.0894841775 * color.a - 1.2914855480 * color.b)
      return SIMD3(
        4.0767416621 * l - 3.3077115913 * m + 0.2309699292 * s,
        -1.2684380046 * l + 2.6097574011 * m - 0.3413193965 * s,
        -0.0041960863 * l - 0.7034186147 * m + 1.7076147010 * s
      )
    }

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
    var oklab: Oklab {
      let rgb = linear
      let l = cbrt(0.4122214708 * rgb.x + 0.5363325363 * rgb.y + 0.0514459929 * rgb.z)
      let m = cbrt(0.2119034982 * rgb.x + 0.6806995451 * rgb.y + 0.1073969566 * rgb.z)
      let s = cbrt(0.0883024619 * rgb.x + 0.2817188376 * rgb.y + 0.6299787005 * rgb.z)
      return Oklab(
        lightness: 0.2104542553 * l + 0.7936177850 * m - 0.0040720468 * s,
        a: 1.9779984951 * l - 2.4285922050 * m + 0.4505937099 * s,
        b: 0.0259040371 * l + 0.7827717662 * m - 0.8086757660 * s
      )
    }

    var perceptual: SIMD3<Double> {
      let color = oklab
      return SIMD3(color.lightness, color.a, color.b)
    }

    var hex: String {
      func channel(_ value: Double) -> Int {
        Int((min(max(value, 0), 1) * 255).rounded())
      }
      return String(format: "%02X%02X%02X",
                    channel(components.x),
                    channel(components.y),
                    channel(components.z))
    }
  }
}
