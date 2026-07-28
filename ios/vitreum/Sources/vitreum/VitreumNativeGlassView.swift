import Flutter
import UIKit

final class VitreumNativeGlassView: NSObject, FlutterPlatformView {
  private let container: VitreumGlassHostView

  init(frame: CGRect, arguments: Any?) {
    container = VitreumGlassHostView(frame: frame)
    container.alpha = 1
    container.backgroundColor = .clear
    container.isOpaque = false
    super.init()
    configure(arguments)
  }

  func view() -> UIView { container }

  private func configure(_ arguments: Any?) {
    guard #available(iOS 26.0, *),
          let values = arguments as? [String: Any] else {
      return
    }
    let effectStyle: UIGlassEffect.Style =
      values["style"] as? String == "clear" ? .clear : .regular
    let effect = UIGlassEffect(style: effectStyle)
    effect.isInteractive = values["interactive"] as? Bool ?? false
    if let argb = values["tint"] as? NSNumber {
      effect.tintColor = UIColor.vitreum(argb: argb.uint32Value)
    } else {
      effect.tintColor = nil
    }
    let effectView = UIVisualEffectView(effect: effect)
    effectView.translatesAutoresizingMaskIntoConstraints = false
    effectView.alpha = 1
    effectView.backgroundColor = .clear
    effectView.isOpaque = false
    effectView.isUserInteractionEnabled = effect.isInteractive
    container.addSubview(effectView)
    NSLayoutConstraint.activate([
      effectView.leadingAnchor.constraint(equalTo: container.leadingAnchor),
      effectView.trailingAnchor.constraint(equalTo: container.trailingAnchor),
      effectView.topAnchor.constraint(equalTo: container.topAnchor),
      effectView.bottomAnchor.constraint(equalTo: container.bottomAnchor),
    ])
    container.configureShape(values["shape"])
  }
}

private final class VitreumGlassHostView: UIView {
  private var shapeKind = "roundedRectangle"
  private var requestedRadius: CGFloat = 24

  override init(frame: CGRect) {
    super.init(frame: frame)
    isOpaque = false
    clipsToBounds = true
    layer.cornerCurve = .continuous
  }

  required init?(coder: NSCoder) {
    nil
  }

  func configureShape(_ argument: Any?) {
    guard let shape = argument as? [String: Any] else { return }
    shapeKind = shape["kind"] as? String ?? "roundedRectangle"
    requestedRadius = CGFloat(
      max(0, min((shape["radius"] as? NSNumber)?.doubleValue ?? 24, 10_000))
    )
    setNeedsLayout()
  }

  override func layoutSubviews() {
    super.layoutSubviews()
    if shapeKind == "circle" || shapeKind == "capsule" {
      layer.cornerRadius = min(bounds.width, bounds.height) / 2
    } else {
      layer.cornerRadius = min(requestedRadius, min(bounds.width, bounds.height) / 2)
    }
  }
}

private extension UIColor {
  static func vitreum(argb: UInt32) -> UIColor {
    UIColor(
      red: CGFloat((argb >> 16) & 0xff) / 255,
      green: CGFloat((argb >> 8) & 0xff) / 255,
      blue: CGFloat(argb & 0xff) / 255,
      alpha: CGFloat((argb >> 24) & 0xff) / 255
    )
  }
}
