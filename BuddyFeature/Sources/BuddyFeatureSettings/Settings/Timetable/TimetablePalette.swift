//
//  TimetablePalette.swift
//  BuddyFeature
//
//  Created by Soongyu Kwon on 16/09/2026.
//

import Foundation

/// The colours a generated theme is made of: the cells courses cycle through,
/// the text on top of them, the grid's background, its separators, and its day
/// and hour labels.
///
/// Built by ``derived(seeds:dominant:isDark:cellCount:)`` from a few seed
/// colours, wherever those came from — the clusters of a photo
/// (``TimetablePhotoPalette``) or the anchors the on-device model answers a
/// description with. Both routes share this code so a generated theme is held
/// to the same legibility, and looks like it came from the same app, either
/// way.
struct TimetablePalette: Equatable, Sendable {
  let colors: [String]
  let text: String
  let background: String
  let separator: String
  let gridLabel: String
}

extension TimetablePalette {
  /// Text clears the surface behind it by this ratio: a little above the 4.5:1
  /// minimum, so rounding to eight bits per channel cannot drop it below.
  static let readableContrast = 4.7

  /// Derives every colour role from the seeds.
  ///
  /// - Parameters:
  ///   - seeds: Distinct colours to build the cells from, most important first.
  ///   - dominant: The colour the theme is mostly made of, which decides the
  ///     tint of the background, the text and the labels.
  ///   - isDark: Whether the grid reads as dark. Decided by the caller, which
  ///     knows whether it is looking at a photo or at what someone asked for.
  ///   - cellCount: How many cell colours to produce.
  static func derived(
    seeds: [Oklab],
    dominant: Oklab,
    isDark: Bool,
    cellCount: Int
  ) -> TimetablePalette {
    // The background *is* the dominant colour, taken only as far towards black
    // or white as legible text needs. Mixing it almost entirely into black —
    // the naive way to darken — throws away the very colour it should echo, so
    // the grid stops looking like the thing it came from.
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

    return TimetablePalette(
      colors: cellColors(
        seeds: seeds,
        background: background,
        text: text,
        isDark: isDark,
        cellCount: cellCount
      ),
      text: text.rgb.hex,
      background: background.rgb.hex,
      separator: separator.rgb.hex,
      gridLabel: gridLabel.rgb.hex
    )
  }

  /// Cell colours are the seeds themselves — same hues, same order of
  /// importance — placed in a lightness band that sits clear of both the
  /// background and the text. With fewer seeds than cells, the later cells
  /// repeat those hues as lighter and darker variants instead of inventing new
  /// ones, which is what keeps the palette reading as one picture.
  private static func cellColors(
    seeds: [Oklab],
    background: Oklab,
    text: Oklab,
    isDark: Bool,
    cellCount: Int
  ) -> [String] {
    guard !seeds.isEmpty, cellCount > 0 else { return [] }

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

    // Seeds are spaced evenly across the band by their order of lightness
    // rather than by the distance between them: the band is far narrower than
    // a photo's range of lightness, and squeezing the real spacing into it
    // leaves two seeds that differed only in lightness looking like one
    // colour.
    let ranks = ranks(of: seeds)
    let rounds = (cellCount + seeds.count - 1) / seeds.count
    let offsets = variations(rounds)
    // A pale seed stays the paler cell, so the palette keeps the order the eye
    // read. The more passes it takes to fill the cells, the less that order is
    // worth holding on to: cells drawn from two hues have to use the whole
    // band to stay apart, while a seed per cell can each keep the place it
    // had.
    let anchor = min(0.8, 1 / Double(rounds))

    return (0..<cellCount).map { index in
      let seed = seeds[index % seeds.count]
      let round = index / seeds.count
      let rank = ranks[index % seeds.count]
      let tone = min(max(anchor * rank + (1 - anchor) * (0.5 + offsets[round] * 0.95), 0), 1)
      // Averaging a cluster costs it some chroma, and the boost puts that
      // back. Near-neutral seeds are left alone: their hue is only noise, and
      // saturating it would invent a colour that was never asked for.
      let chroma = seed.chroma < 0.012
        ? seed.chroma
        : min(seed.chroma * max(1.15 - 0.1 * Double(round), 0.7), 0.16)
      return Oklab(
        lightness: band.lowerBound + (band.upperBound - band.lowerBound) * tone,
        chroma: chroma,
        // Later passes lean a few degrees off the seed's hue — an analogous
        // shade, never a new colour — which is what keeps three blues from
        // yielding sixteen cells nobody can tell apart. A near-neutral seed
        // has no hue to lean on, and stays neutral.
        hue: seed.hue + 0.5 * offsets[round]
      )
      .contrasting(with: text.rgb, darker: isDark)
      .rgb
      .hex
    }
  }

  /// Folds colours that would produce the same cell into one seed.
  ///
  /// A cell keeps its seed's hue and chroma but is given the band's lightness,
  /// so two colours that share hue and chroma arrive as the same cell however
  /// far apart they started — a sky's dark and pale blues otherwise fill half
  /// the palette with one colour. Seeds are therefore chosen for distinctness
  /// in hue and chroma alone, most important first, and the band's own
  /// variations then fan each one into light and dark cells deliberately.
  static func distinctSeeds(from colors: [Oklab]) -> [Oklab] {
    var seeds: [Oklab] = []
    for color in colors {
      let isDistinct = seeds.allSatisfy { seed in
        let delta = SIMD2(seed.a - color.a, seed.b - color.b)
        return (delta.x * delta.x + delta.y * delta.y).squareRoot() >= 0.03
      }
      if isDistinct { seeds.append(color) }
    }
    return seeds
  }

  /// Each seed's place in the order of lightness, from 0 for the darkest to 1
  /// for the lightest, with a single seed sitting in the middle.
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
  /// first pass over the seeds uses them close to the lightness they arrived
  /// with, and later passes fan out around it.
  private static func variations(_ count: Int) -> [Double] {
    guard count > 1 else { return [0] }
    return (0..<count)
      .map { -0.5 + Double($0) / Double(count - 1) }
      .sorted { abs($0) == abs($1) ? $0 > $1 : abs($0) < abs($1) }
  }
}

// MARK: - Colour spaces

extension TimetablePalette {
  /// OKLab, addressed as lightness, chroma and hue: the form that lets a
  /// colour be made readable by moving its lightness alone, instead of mixing
  /// it into black or white and washing the original colour out of it.
  struct Oklab {
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

    /// OKLab describes colours sRGB cannot show, so chroma — never lightness
    /// or hue — is given up until the colour fits. Clipping the channels
    /// instead would shift the hue, and a family of shades would stop
    /// matching.
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

    /// Luminance rises with lightness at a fixed hue and chroma, so a
    /// bisection lands on the requested luminance without touching either.
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

  struct RGB {
    let components: SIMD3<Double>

    init(_ components: SIMD3<Double>) { self.components = components }

    /// `nil` when the colour falls outside sRGB, so the caller can bring it
    /// back into gamut on its own terms.
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
