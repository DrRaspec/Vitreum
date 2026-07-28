import Flutter
import UIKit

public final class VitreumPlugin: NSObject, FlutterPlugin {
  public static func register(with registrar: FlutterPluginRegistrar) {
    let instance = VitreumPlugin()
    let channel = FlutterMethodChannel(
      name: "dev.vitreum/capabilities",
      binaryMessenger: registrar.messenger()
    )
    registrar.addMethodCallDelegate(instance, channel: channel)
    registrar.register(
      VitreumNativeGlassFactory(),
      withId: "dev.vitreum/native_glass"
    )
    registrar.register(
      VitreumNativeDiagnosticFactory(),
      withId: "dev.vitreum/native_diagnostic"
    )
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard call.method == "getCapabilities" else {
      result(FlutterMethodNotImplemented)
      return
    }
    result(VitreumNativeCapabilities.current())
  }
}
