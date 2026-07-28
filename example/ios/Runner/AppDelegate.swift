import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  private lazy var nativeTabEngineGroup = FlutterEngineGroup(
    name: "dev.vitreum.native-tabs",
    project: nil
  )
  private var nativeTabChannel: FlutterMethodChannel?

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    let channel = FlutterMethodChannel(
      name: "dev.vitreum/native_tab_scaffold",
      binaryMessenger: engineBridge.applicationRegistrar.messenger()
    )
    channel.setMethodCallHandler { [weak self] call, result in
      guard call.method == "present" else {
        result(FlutterMethodNotImplemented)
        return
      }
      self?.presentNativeTabScaffold(arguments: call.arguments, result: result)
    }
    nativeTabChannel = channel
  }

  private func presentNativeTabScaffold(
    arguments: Any?,
    result: @escaping FlutterResult
  ) {
    guard
      let values = arguments as? [String: Any],
      let contentName = values["content"] as? String,
      let content = VitreumNativeTabContent(rawValue: contentName)
    else {
      result(
        FlutterError(
          code: "invalid-arguments",
          message: "Expected native or flutter tab content.",
          details: nil
        )
      )
      return
    }
    let minimizeName = values["minimizeBehavior"] as? String ?? "automatic"
    let minimizeSetting =
      VitreumTabMinimizeSetting(rawValue: minimizeName) ?? .automatic
    let automate = values["automate"] as? Bool ?? false

    guard let presenter = activePresenter() else {
      result(
        FlutterError(
          code: "no-presenter",
          message: "No active iOS view controller can present the tab scaffold.",
          details: nil
        )
      )
      return
    }

    let tabs = VitreumNativeTabScaffold(
      content: content,
      minimizeSetting: minimizeSetting,
      engineGroup: nativeTabEngineGroup,
      automate: automate
    )
    tabs.modalPresentationStyle = .fullScreen
    presenter.present(tabs, animated: true) {
      result(nil)
    }
  }

  private func activePresenter() -> UIViewController? {
    let root = UIApplication.shared.connectedScenes
      .compactMap { $0 as? UIWindowScene }
      .flatMap(\.windows)
      .first(where: \.isKeyWindow)?
      .rootViewController
    var presenter = root
    while let presented = presenter?.presentedViewController {
      presenter = presented
    }
    return presenter
  }
}
