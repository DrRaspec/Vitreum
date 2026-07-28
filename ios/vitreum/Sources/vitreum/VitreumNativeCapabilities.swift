import UIKit

enum VitreumNativeCapabilities {
  static func current() -> [String: Any] {
    var apiAvailable = false
    if #available(iOS 26.0, *) {
      apiAvailable = true
    }
    let reduced = UIAccessibility.isReduceTransparencyEnabled
    let singleOverlayValidated = apiAvailable && !reduced
    return [
      "platform": "ios",
      "osVersion": UIDevice.current.systemVersion,
      "nativeApiExists": apiAvailable,
      "nativeViewCanBeCreated": apiAvailable,
      "nativeBackdropCompositionValidated": false,
      "nativeSingleOverlayCompositionValidated": singleOverlayValidated,
      "nativeInteractiveEffectAvailable": apiAvailable,
      "simulatedRendererAvailable": true,
      "shaderAvailable": false,
      "reducedTransparency": reduced,
      "selectedAutomaticBackend": reduced ? "solid" : "flutterBalanced",
    ]
  }
}
