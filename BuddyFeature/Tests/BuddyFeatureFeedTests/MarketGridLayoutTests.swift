import CoreGraphics
import Testing
@testable import BuddyFeatureShared

/// Sizes from the iPhone Duo simulator: inner display, landscape, inside the safe area.
struct MarketGridLayoutTests {
  @Test func phoneHasTwoColumns() {
    #expect(MarketGridLayout(width: 402, hinge: nil, hasHinge: false).columnWidths.count == 2)
  }

  @Test func foldableDisplayUsesAnEvenColumnCount() {
    // 867 points fit 4.4 ideal columns; without a hinge that rounds to 4, with one it stays even.
    let flat = MarketGridLayout(width: 669, hinge: nil, hasHinge: true)
    #expect(flat.columnWidths.count.isMultiple(of: 2))
  }

  @Test func halfFoldedPutsTheHingeInTheMiddleGutter() throws {
    let hinge = CGRect(x: 455.5, y: 0, width: 40, height: 611)
    let layout = MarketGridLayout(width: 867, hinge: hinge, hasHinge: true)
    let count = layout.columnWidths.count
    #expect(count.isMultiple(of: 2))

    // Walk the columns: the gap after the left half must be exactly the hinge band.
    var x = layout.leadingInset
    var leftHalfEnd: CGFloat = 0
    for index in 0..<count {
      x += layout.columnWidths[index]
      if index == count / 2 - 1 { leftHalfEnd = x }
      if index < count - 1 { x += layout.gaps[index] }
    }
    #expect(abs(leftHalfEnd - hinge.minX) < 0.5)
    #expect(abs((leftHalfEnd + layout.gaps[count / 2 - 1]) - hinge.maxX) < 0.5)
    // Nothing runs off the trailing margin.
    #expect(x <= 867 - 16 + 0.5)
  }

  @Test(arguments: [(402.0, 874.0), (1032.0, 1376.0), (1376.0, 1032.0)])
  func placeholderFillsTheViewport(width: Double, height: Double) {
    var layout = MarketGridLayout(width: width, hinge: nil, hasHinge: false)
    layout.viewportHeight = height
    let columns = layout.columnWidths.count
    let rows = layout.placeholderCount / columns
    #expect(layout.placeholderCount.isMultiple(of: columns))
    // The rows reach the bottom of the screen even when every title is one line.
    #expect(CGFloat(rows) * (layout.columnWidths[0] + 60 + 20) >= height)
  }
}
