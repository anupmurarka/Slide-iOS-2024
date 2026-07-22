//
//  MDCActivityIndicator.swift
//  Slide for Reddit
//
//  Native replacement for Google's archived MaterialComponents `MDCActivityIndicator`.
//  Implements only the small API surface the app used (init, cycleColors,
//  indicatorMode, radius, strokeWidth, progress, start/stopAnimating) on top of
//  UIKit: a `UIActivityIndicatorView` for the indeterminate mode and a
//  `CAShapeLayer` ring for the determinate mode. Introduced during the
//  MaterialComponents removal (see MIGRATION.md, Phase 4).
//

import UIKit

enum MDCActivityIndicatorMode {
    case indeterminate
    case determinate
}

final class MDCActivityIndicator: UIView {

    // MARK: - MDC-compatible API

    var cycleColors: [UIColor] = [.gray] {
        didSet { applyColor() }
    }

    var indicatorMode: MDCActivityIndicatorMode = .indeterminate {
        didSet { updateMode() }
    }

    /// Progress in 0...1, used only in `.determinate` mode.
    var progress: Float = 0 {
        didSet { updateProgressStroke() }
    }

    /// Radius of the ring in `.determinate` mode (points).
    var radius: CGFloat = 9 {
        didSet { setNeedsLayout() }
    }

    /// Stroke width of the ring in `.determinate` mode (points).
    var strokeWidth: CGFloat = 2 {
        didSet {
            progressRing.lineWidth = strokeWidth
            setNeedsLayout()
        }
    }

    private(set) var isAnimating = false

    // MARK: - Backing views

    private let spinner = UIActivityIndicatorView(style: .large)
    private let progressRing = CAShapeLayer()

    // MARK: - Init

    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }

    private func commonInit() {
        spinner.hidesWhenStopped = true
        addSubview(spinner)

        progressRing.fillColor = UIColor.clear.cgColor
        progressRing.lineWidth = strokeWidth
        progressRing.lineCap = .round
        progressRing.strokeEnd = 0
        progressRing.isHidden = true
        layer.addSublayer(progressRing)

        applyColor()
    }

    // MARK: - Layout

    override func layoutSubviews() {
        super.layoutSubviews()
        spinner.center = CGPoint(x: bounds.midX, y: bounds.midY)

        let ringPath = UIBezierPath(
            arcCenter: CGPoint(x: bounds.midX, y: bounds.midY),
            radius: radius,
            startAngle: -.pi / 2,
            endAngle: 3 * .pi / 2,
            clockwise: true
        )
        progressRing.path = ringPath.cgPath
        progressRing.frame = bounds
    }

    override var intrinsicContentSize: CGSize {
        let dimension = (radius + strokeWidth) * 2
        return CGSize(width: dimension, height: dimension)
    }

    // MARK: - Behaviour

    func startAnimating() {
        isAnimating = true
        updateMode()
    }

    func stopAnimating() {
        isAnimating = false
        spinner.stopAnimating()
        progressRing.isHidden = true
    }

    private func updateMode() {
        guard isAnimating else { return }
        switch indicatorMode {
        case .indeterminate:
            progressRing.isHidden = true
            spinner.startAnimating()
        case .determinate:
            spinner.stopAnimating()
            progressRing.isHidden = false
            updateProgressStroke()
        }
    }

    private func updateProgressStroke() {
        progressRing.strokeEnd = CGFloat(max(0, min(1, progress)))
    }

    private func applyColor() {
        let color = cycleColors.first ?? .gray
        spinner.color = color
        progressRing.strokeColor = color.cgColor
    }
}
