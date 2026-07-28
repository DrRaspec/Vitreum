import Flutter
import UIKit

final class VitreumNativeDiagnosticFactory: NSObject, FlutterPlatformViewFactory {
  func createArgsCodec() -> FlutterMessageCodec & NSObjectProtocol {
    FlutterStandardMessageCodec.sharedInstance()
  }

  func create(
    withFrame frame: CGRect,
    viewIdentifier viewId: Int64,
    arguments args: Any?
  ) -> FlutterPlatformView {
    VitreumNativeDiagnosticView(frame: frame)
  }
}

final class VitreumNativeDiagnosticView: NSObject, FlutterPlatformView {
  private let root: NativeDiagnosticRootView

  init(frame: CGRect) {
    root = NativeDiagnosticRootView(frame: frame)
    super.init()
  }

  func view() -> UIView { root }
}

private final class NativeDiagnosticRootView: UIView {
  private let gradient = CAGradientLayer()
  private let stripes = CAShapeLayer()
  private let frameLabel = UILabel()
  private let movingLabel = UILabel()
  private var displayLink: CADisplayLink?
  private var frameNumber = 0
  private var phase: CGFloat = 0

  override init(frame: CGRect) {
    super.init(frame: frame)
    alpha = 1
    isOpaque = true
    backgroundColor = .black
    configureBackground()
    configureLabels()
    configureGlass()
    displayLink = CADisplayLink(target: self, selector: #selector(tick))
    displayLink?.add(to: .main, forMode: .common)
  }

  required init?(coder: NSCoder) { nil }

  deinit {
    displayLink?.invalidate()
  }

  override func layoutSubviews() {
    super.layoutSubviews()
    gradient.frame = bounds
    stripes.frame = bounds
    rebuildStripePath()
  }

  private func configureBackground() {
    gradient.colors = [
      UIColor(red: 0.03, green: 0.08, blue: 0.20, alpha: 1).cgColor,
      UIColor(red: 0.11, green: 0.48, blue: 0.92, alpha: 1).cgColor,
      UIColor(red: 0.86, green: 0.20, blue: 0.48, alpha: 1).cgColor,
      UIColor(red: 0.16, green: 0.82, blue: 0.64, alpha: 1).cgColor,
    ]
    gradient.locations = [0, 0.34, 0.68, 1]
    gradient.startPoint = CGPoint(x: 0, y: 0)
    gradient.endPoint = CGPoint(x: 1, y: 1)
    layer.addSublayer(gradient)

    stripes.fillColor = UIColor.clear.cgColor
    stripes.strokeColor = UIColor.white.withAlphaComponent(0.88).cgColor
    stripes.lineWidth = 8
    layer.addSublayer(stripes)
  }

  private func configureGlass() {
    guard #available(iOS 26.0, *) else { return }
    let effect = UIGlassEffect(style: .regular)
    effect.isInteractive = true
    effect.tintColor = nil
    let glass = UIVisualEffectView(effect: effect)
    glass.translatesAutoresizingMaskIntoConstraints = false
    glass.alpha = 1
    glass.backgroundColor = .clear
    glass.isOpaque = false
    glass.layer.cornerRadius = 36
    glass.layer.cornerCurve = .continuous
    glass.clipsToBounds = true
    addSubview(glass)

    let label = UILabel()
    label.translatesAutoresizingMaskIntoConstraints = false
    label.text = "VALID NATIVE HIERARCHY"
    label.font = .systemFont(ofSize: 15, weight: .semibold)
    label.textAlignment = .center
    label.textColor = .label
    glass.contentView.addSubview(label)

    NSLayoutConstraint.activate([
      glass.centerXAnchor.constraint(equalTo: centerXAnchor),
      glass.centerYAnchor.constraint(equalTo: centerYAnchor),
      glass.widthAnchor.constraint(equalToConstant: 310),
      glass.heightAnchor.constraint(equalToConstant: 112),
      label.centerXAnchor.constraint(equalTo: glass.contentView.centerXAnchor),
      label.centerYAnchor.constraint(equalTo: glass.contentView.centerYAnchor),
    ])
  }

  private func configureLabels() {
    let diagnostic = UILabel()
    diagnostic.translatesAutoresizingMaskIntoConstraints = false
    diagnostic.text = "PURE NATIVE"
    diagnostic.font = .systemFont(ofSize: 17, weight: .bold)
    diagnostic.textColor = .white
    diagnostic.backgroundColor = .systemRed
    diagnostic.textAlignment = .center
    diagnostic.layer.cornerRadius = 12
    diagnostic.clipsToBounds = true
    addSubview(diagnostic)

    frameLabel.translatesAutoresizingMaskIntoConstraints = false
    frameLabel.font = .monospacedDigitSystemFont(ofSize: 15, weight: .bold)
    frameLabel.textColor = .white
    addSubview(frameLabel)

    movingLabel.font = .monospacedSystemFont(ofSize: 18, weight: .bold)
    movingLabel.textColor = .white
    movingLabel.text = "MOVING NATIVE TEXT"
    addSubview(movingLabel)

    NSLayoutConstraint.activate([
      diagnostic.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor, constant: 18),
      diagnostic.centerXAnchor.constraint(equalTo: centerXAnchor),
      diagnostic.widthAnchor.constraint(equalToConstant: 150),
      diagnostic.heightAnchor.constraint(equalToConstant: 42),
      frameLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 18),
      frameLabel.bottomAnchor.constraint(equalTo: safeAreaLayoutGuide.bottomAnchor, constant: -18),
    ])
  }

  private func rebuildStripePath() {
    let path = UIBezierPath()
    var x: CGFloat = -bounds.height
    while x < bounds.width + bounds.height {
      path.move(to: CGPoint(x: x, y: 0))
      path.addLine(to: CGPoint(x: x + bounds.height, y: bounds.height))
      x += 54
    }
    stripes.path = path.cgPath
  }

  @objc private func tick() {
    frameNumber += 1
    phase += 0.012
    CATransaction.begin()
    CATransaction.setDisableActions(true)
    gradient.startPoint = CGPoint(
      x: 0.5 + cos(phase) * 0.48,
      y: 0.5 + sin(phase * 0.7) * 0.48
    )
    gradient.endPoint = CGPoint(
      x: 0.5 - cos(phase) * 0.48,
      y: 0.5 - sin(phase * 0.7) * 0.48
    )
    stripes.setAffineTransform(CGAffineTransform(translationX: (phase * 90).truncatingRemainder(dividingBy: 54), y: 0))
    CATransaction.commit()

    frameLabel.text = String(format: "FRAME %06d", frameNumber)
    let travel = max(bounds.width - 230, 1)
    movingLabel.frame = CGRect(
      x: (phase * 70).truncatingRemainder(dividingBy: travel),
      y: bounds.midY + 100,
      width: 230,
      height: 30
    )
  }
}
