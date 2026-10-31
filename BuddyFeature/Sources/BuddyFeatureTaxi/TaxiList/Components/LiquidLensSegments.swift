//
//  LiquidLensSegments.swift
//  BuddyFeatureTaxi
//
//  Created by Soongyu Kwon on 30/10/2026.
//

import SwiftUI
import UIKit
import Haptica

/// A row of equal-width segments whose selection is UIKit's liquid glass lens, as in the tab bar
/// and segmented controls: tapping a segment slides the lens to it, and swiping lifts it into glass
/// that magnifies the segments as it follows your finger.
///
/// The lens is the private `_UILiquidLensView`. Where it's missing, the selection is a plain pill.
struct LiquidLensSegments<Segment: View>: UIViewRepresentable {
  let count: Int
  let selectedIndex: Int
  /// The resting selection's colour for each segment.
  let selectionColors: [Color]
  let cornerRadius: CGFloat
  var onSelect: (Int) -> Void
  /// Draws a segment; `isSelected` is true only while the selection rests on it, not while lifted.
  @ViewBuilder var segment: (_ index: Int, _ isSelected: Bool) -> Segment

  func makeUIView(context: Context) -> LiquidLensSegmentsView {
    LiquidLensSegmentsView(cornerRadius: cornerRadius)
  }

  func updateUIView(_ view: LiquidLensSegmentsView, context: Context) {
    let redactionReasons = context.environment.redactionReasons
    view.count = count
    view.selectionColors = selectionColors.map(UIColor.init)
    view.onSelect = onSelect
    view.isUserInteractionEnabled = context.environment.isEnabled
    // A hosted view doesn't inherit this environment, so it's passed on.
    view.render = { selectedIndex in
      AnyView(
        HStack(spacing: 0) {
          ForEach(0..<count, id: \.self) { index in
            segment(index, index == selectedIndex)
              .frame(maxWidth: .infinity, maxHeight: .infinity)
          }
        }
        .redacted(reason: redactionReasons)
      )
    }
    view.select(selectedIndex, animated: context.transaction.animation != nil)
  }

  func sizeThatFits(_ proposal: ProposedViewSize, uiView: LiquidLensSegmentsView, context: Context) -> CGSize? {
    let width = proposal.width ?? 320
    return CGSize(width: width, height: uiView.contentHeight(forWidth: width))
  }
}

final class LiquidLensSegmentsView: UIView {
  var count = 0 {
    didSet { if count != oldValue { setNeedsLayout() } }
  }
  var selectionColors: [UIColor] = [] {
    didSet { updateSelectionColor() }
  }
  var onSelect: ((Int) -> Void)?
  var render: ((_ selectedIndex: Int?) -> AnyView)? {
    didSet { updateContent() }
  }

  private(set) var selectedIndex = 0
  /// The segment under your finger while swiping.
  private var draggedIndex: Int?
  /// Whether the touch under way became a swipe or a scroll, which then decides where the lens
  /// lands rather than letting go of the touch.
  private var touchWasTakenOver = false
  private var touchStart: CGPoint = .zero
  private var isLifted = false

  private let content = UIHostingController(rootView: AnyView(EmptyView()))
  /// The resting selection, behind the lens's glass when there is one.
  private let pill = UIView()
  private let lens: LiquidLens?
  private let horizontalOnly = HorizontalPanDelegate()
  private var selection: UIView { lens.map { $0 as! UIView } ?? pill }

  init(cornerRadius: CGFloat) {
    pill.layer.cornerRadius = cornerRadius
    pill.layer.cornerCurve = .continuous
    pill.autoresizingMask = [.flexibleWidth, .flexibleHeight]
    lens = LiquidLensFactory.make(restingBackground: pill)
    super.init(frame: .zero)

    content.view.backgroundColor = .clear
    // Touches go to this view, which tracks them; the hosted segments only draw.
    content.view.isUserInteractionEnabled = false
    content.safeAreaRegions = []
    content.sizingOptions = []

    // Like a segmented control: the lens below the segments, magnifying them once lifted.
    addSubview(selection)
    addSubview(content.view)
    if let lens {
      lens.style = 1
      lens.liftedContentView = content.view
    }

    // Touches still arrive once a swipe begins, so a swipe's end isn't mistaken for a scroll's.
    let pan = UIPanGestureRecognizer(target: self, action: #selector(panned(_:)))
    pan.cancelsTouchesInView = false
    pan.delegate = horizontalOnly
    addGestureRecognizer(pan)
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func layoutSubviews() {
    super.layoutSubviews()
    content.view.frame = bounds
    if draggedIndex == nil && !isLifted {
      selection.frame = frame(for: selectedIndex)
    }
  }

  func contentHeight(forWidth width: CGFloat) -> CGFloat {
    let fitting = content.sizeThatFits(in: CGSize(width: width, height: .greatestFiniteMagnitude))
    return max(60, fitting.height)
  }

  /// Moves the selection to `index` when it was changed from outside, unless you're swiping.
  func select(_ index: Int, animated: Bool) {
    guard draggedIndex == nil, index != selectedIndex, (0..<count).contains(index) else { return }
    selectedIndex = index
    updateSelectionColor()
    updateContent()
    let move = { self.selection.frame = self.frame(for: index) }
    if animated && window != nil {
      UIView.animate(springDuration: 0.35, bounce: 0.2, animations: move)
    } else {
      move()
    }
  }

  // MARK: - Gestures

  // Like the tab bar, the lens lifts as soon as you touch a segment and moves to it, then settles
  // there when you let go, or follows your finger if you swipe.

  override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
    super.touchesBegan(touches, with: event)
    guard let touch = touches.first, let index = index(at: touch.location(in: self)) else { return }
    touchWasTakenOver = false
    touchStart = touch.location(in: self)
    draggedIndex = index
    if index != selectedIndex { Haptic.selection.generate() }
    setLifted(true)
    UIView.animate(springDuration: 0.3, bounce: 0.2) {
      self.selection.frame = self.liftedFrame(for: index)
    }
  }

  /// A mostly vertical drag is someone scrolling, not choosing a day, even before the scroll view
  /// takes the touch.
  override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
    super.touchesMoved(touches, with: event)
    guard !touchWasTakenOver, let touch = touches.first else { return }
    let location = touch.location(in: self)
    let dx = abs(location.x - touchStart.x)
    let dy = abs(location.y - touchStart.y)
    guard dy > 10, dy > dx else { return }
    touchWasTakenOver = true
    land(on: selectedIndex)
  }

  override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
    super.touchesEnded(touches, with: event)
    guard !touchWasTakenOver else { return }
    land(on: draggedIndex ?? selectedIndex)
  }

  /// The touch became a scroll: the lens goes back to the day that was already selected.
  override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
    super.touchesCancelled(touches, with: event)
    guard !touchWasTakenOver else { return }
    land(on: selectedIndex)
  }

  @objc private func panned(_ pan: UIPanGestureRecognizer) {
    let x = pan.location(in: self).x
    switch pan.state {
    case .began:
      touchWasTakenOver = true
      draggedIndex = index(at: CGPoint(x: x, y: 0)) ?? draggedIndex ?? selectedIndex
      setLifted(true)
      UIView.animate(springDuration: 0.25, bounce: 0.15) { self.follow(x) }
    case .changed:
      follow(x)
      let index = index(at: CGPoint(x: x, y: 0)) ?? draggedIndex
      if index != draggedIndex {
        Haptic.selection.generate()
        draggedIndex = index
      }
    case .ended, .cancelled, .failed:
      land(on: draggedIndex ?? selectedIndex)
    default:
      break
    }
  }

  /// Selects `index` and puts the lens down there.
  private func land(on index: Int) {
    draggedIndex = nil
    let changed = index != selectedIndex
    selectedIndex = index
    UIView.animate(springDuration: 0.35, bounce: 0.2) {
      self.selection.frame = self.liftedFrame(for: index)
    } completion: { _ in
      self.settle()
    }
    if changed { onSelect?(index) }
  }

  // MARK: - Selection

  private func follow(_ x: CGFloat) {
    var frame = liftedFrame(for: selectedIndex)
    frame.origin.x = min(
      max(x - frame.width / 2, -liftedOutset.width),
      bounds.width - frame.width + liftedOutset.width
    )
    selection.frame = frame
  }

  /// Puts the lens down on the selected segment, in its colour, shrinking back to the segment.
  private func settle() {
    guard draggedIndex == nil else { return }
    updateSelectionColor()
    setLifted(false)
    UIView.animate(springDuration: 0.3, bounce: 0.2) {
      self.selection.frame = self.frame(for: self.selectedIndex)
    }
  }

  private func setLifted(_ lifted: Bool) {
    guard lifted != isLifted else { return }
    isLifted = lifted
    lens?.setLifted(lifted, animated: true, alongsideAnimations: nil, completion: nil)
    // The resting pill's colours would be unreadable on clear glass. They fade, as the pill does,
    // rather than leaving a blank pill for a moment.
    UIView.transition(with: content.view, duration: 0.25, options: [.transitionCrossDissolve, .allowUserInteraction]) {
      self.updateContent()
    }
  }

  private func updateSelectionColor() {
    guard selectionColors.indices.contains(selectedIndex) else { return }
    pill.backgroundColor = selectionColors[selectedIndex]
  }

  private func updateContent() {
    guard let render else { return }
    content.rootView = render(isLifted ? nil : selectedIndex)
  }

  private func frame(for index: Int) -> CGRect {
    guard count > 0 else { return .zero }
    let width = bounds.width / CGFloat(count)
    return CGRect(x: width * CGFloat(index), y: 0, width: width, height: bounds.height)
  }

  /// How much the lens grows past its segment while lifted: as much as the tab bar's, whose lens
  /// goes from 84×54pt resting to 105×73pt lifted.
  private static let liftedScale = CGSize(width: 1.25, height: 1.35)

  /// How far the lifted lens reaches past its segment on each side.
  private var liftedOutset: CGSize {
    let frame = frame(for: selectedIndex)
    return CGSize(
      width: frame.width * (Self.liftedScale.width - 1) / 2,
      height: frame.height * (Self.liftedScale.height - 1) / 2
    )
  }

  private func liftedFrame(for index: Int) -> CGRect {
    frame(for: index).insetBy(dx: -liftedOutset.width, dy: -liftedOutset.height)
  }

  private func index(at point: CGPoint) -> Int? {
    guard count > 0, bounds.width > 0 else { return nil }
    return min(max(Int(point.x / (bounds.width / CGFloat(count))), 0), count - 1)
  }
}

/// Only horizontal swipes move the selection; vertical ones scroll whatever it sits in.
private final class HorizontalPanDelegate: NSObject, UIGestureRecognizerDelegate {
  func gestureRecognizerShouldBegin(_ gesture: UIGestureRecognizer) -> Bool {
    guard let pan = gesture as? UIPanGestureRecognizer else { return true }
    let translation = pan.translation(in: pan.view)
    return abs(translation.x) > abs(translation.y)
  }
}

// MARK: - _UILiquidLensView

/// The parts of `_UILiquidLensView` used here, as UIKit's segmented control uses them: a resting
/// background drawn while it's down, and content it magnifies while lifted.
@objc private protocol LiquidLens: NSObjectProtocol {
  init(restingBackground: UIView)
  var style: Int { get set }
  weak var liftedContentView: UIView? { get set }
  func setLifted(
    _ lifted: Bool,
    animated: Bool,
    alongsideAnimations: (() -> Void)?,
    completion: (() -> Void)?
  )
}

private enum LiquidLensFactory {
  static func make(restingBackground: UIView) -> LiquidLens? {
    guard let lensClass = NSClassFromString("_UILiquidLensView"), lensClass is UIView.Type else { return nil }
    let selectors = [
      "initWithRestingBackground:", "setStyle:", "setLiftedContentView:",
      "setLifted:animated:alongsideAnimations:completion:",
    ]
    guard selectors.allSatisfy({ lensClass.instancesRespond(to: NSSelectorFromString($0)) }) else { return nil }
    return unsafeBitCast(lensClass, to: LiquidLens.Type.self).init(restingBackground: restingBackground)
  }
}
