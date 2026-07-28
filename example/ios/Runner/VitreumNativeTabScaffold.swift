import Flutter
import UIKit

enum VitreumNativeTabContent: String {
  case native
  case flutter
}

enum VitreumTabMinimizeSetting: String {
  case automatic
  case never
  case onScrollDown
  case onScrollUp
}

/// Example-host reference for Apple's actual system tab-bar controller.
///
/// This is intentionally not a Flutter platform view. `UITabBarController`
/// owns both its child view controllers and its unmodified `UITabBar`.
final class VitreumNativeTabScaffold: UITabBarController {
  private var flutterEngines: [FlutterEngine] = []
  private let automate: Bool
  private var hasAutomated = false

  init(
    content: VitreumNativeTabContent,
    minimizeSetting: VitreumTabMinimizeSetting,
    engineGroup: FlutterEngineGroup,
    automate: Bool = false
  ) {
    self.automate = automate
    super.init(nibName: nil, bundle: nil)

    let controllers: [UIViewController]
    switch content {
    case .native:
      controllers = [
        makeNativeTab(
          title: "Showcase",
          symbol: "sparkles",
          selectedSymbol: "sparkles",
          page: .showcase
        ),
        makeNativeTab(
          title: "Diagnostics",
          symbol: "gauge.with.dots.needle.67percent",
          selectedSymbol: "gauge.with.dots.needle.100percent",
          page: .diagnostics
        ),
      ]
    case .flutter:
      controllers = [
        makeFlutterTab(
          title: "Showcase",
          symbol: "sparkles",
          selectedSymbol: "sparkles",
          entrypoint: "vitreumShowcaseTabMain",
          engineGroup: engineGroup
        ),
        makeFlutterTab(
          title: "Diagnostics",
          symbol: "gauge.with.dots.needle.67percent",
          selectedSymbol: "gauge.with.dots.needle.100percent",
          entrypoint: "vitreumDiagnosticsTabMain",
          engineGroup: engineGroup
        ),
      ]
    }
    viewControllers = controllers

    if #available(iOS 26.0, *) {
      tabBarMinimizeBehavior = switch minimizeSetting {
      case .automatic: .automatic
      case .never: .never
      case .onScrollDown: .onScrollDown
      case .onScrollUp: .onScrollUp
      }
    }
  }

  required init?(coder: NSCoder) {
    nil
  }

  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
    guard automate, !hasAutomated else { return }
    hasAutomated = true
    runReferenceAutomation()
  }

  private func runReferenceAutomation() {
    DispatchQueue.main.asyncAfter(deadline: .now() + 6) { [weak self] in
      self?.selectedIndex = 1
    }
    DispatchQueue.main.asyncAfter(deadline: .now() + 7) { [weak self] in
      self?.selectedIndex = 0
    }
    DispatchQueue.main.asyncAfter(deadline: .now() + 8) { [weak self] in
      self?.selectedNativeTable?.setContentOffset(
        CGPoint(x: 0, y: 940),
        animated: true
      )
    }
    DispatchQueue.main.asyncAfter(deadline: .now() + 10) { [weak self] in
      guard let table = self?.selectedNativeTable else { return }
      table.setContentOffset(
        CGPoint(x: 0, y: -table.adjustedContentInset.top),
        animated: true
      )
    }
    DispatchQueue.main.asyncAfter(deadline: .now() + 13) { [weak self] in
      guard self?.viewIfLoaded?.window != nil else { return }
      self?.runReferenceAutomation()
    }
  }

  private var selectedNativeTable: UITableView? {
    let navigation = selectedViewController as? UINavigationController
    return (navigation?.topViewController as? UITableViewController)?.tableView
  }

  private func makeNativeTab(
    title: String,
    symbol: String,
    selectedSymbol: String,
    page: VitreumNativePage
  ) -> UIViewController {
    let content = VitreumNativeScrollingViewController(page: page)
    configureNavigation(
      content,
      diagnosticLabel: "SYSTEM UITABBARCONTROLLER"
    )
    let navigation = UINavigationController(rootViewController: content)
    navigation.tabBarItem = makeTabBarItem(
      title: title,
      symbol: symbol,
      selectedSymbol: selectedSymbol
    )
    return navigation
  }

  private func makeFlutterTab(
    title: String,
    symbol: String,
    selectedSymbol: String,
    entrypoint: String,
    engineGroup: FlutterEngineGroup
  ) -> UIViewController {
    let options = FlutterEngineGroupOptions()
    options.entrypoint = entrypoint
    let engine = engineGroup.makeEngine(with: options)
    GeneratedPluginRegistrant.register(with: engine)
    flutterEngines.append(engine)

    let content = FlutterViewController(
      engine: engine,
      nibName: nil,
      bundle: nil
    )
    configureNavigation(
      content,
      diagnosticLabel: "SYSTEM UITABBAR + FLUTTER CONTENT"
    )
    let navigation = UINavigationController(rootViewController: content)
    navigation.tabBarItem = makeTabBarItem(
      title: title,
      symbol: symbol,
      selectedSymbol: selectedSymbol
    )
    return navigation
  }

  private func makeTabBarItem(
    title: String,
    symbol: String,
    selectedSymbol: String
  ) -> UITabBarItem {
    UITabBarItem(
      title: title,
      image: UIImage(systemName: symbol),
      selectedImage: UIImage(systemName: selectedSymbol)
    )
  }

  private func configureNavigation(
    _ viewController: UIViewController,
    diagnosticLabel: String
  ) {
    let label = UILabel()
    label.text = diagnosticLabel
    label.font = .systemFont(ofSize: 11, weight: .semibold)
    label.textColor = .secondaryLabel
    label.adjustsFontForContentSizeCategory = true
    viewController.navigationItem.titleView = label
    viewController.navigationItem.leftBarButtonItem = UIBarButtonItem(
      barButtonSystemItem: .close,
      target: self,
      action: #selector(closeReference)
    )
  }

  @objc private func closeReference() {
    dismiss(animated: true)
  }
}

enum VitreumNativePage {
  case showcase
  case diagnostics
}

private final class VitreumNativeScrollingViewController:
  UITableViewController
{
  private let page: VitreumNativePage
  private let colors: [UIColor]

  init(page: VitreumNativePage) {
    self.page = page
    colors = page == .showcase
      ? [.systemOrange, .systemBlue, .systemGreen, .black, .systemYellow]
      : [.secondarySystemBackground, .systemIndigo, .systemTeal, .systemOrange, .black]
    super.init(style: .insetGrouped)
  }

  required init?(coder: NSCoder) {
    nil
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    tableView.separatorStyle = .none
    tableView.backgroundColor = .systemBackground
    tableView.contentInset.bottom = 24
  }

  override func numberOfSections(in tableView: UITableView) -> Int {
    1
  }

  override func tableView(
    _ tableView: UITableView,
    numberOfRowsInSection section: Int
  ) -> Int {
    18
  }

  override func tableView(
    _ tableView: UITableView,
    heightForRowAt indexPath: IndexPath
  ) -> CGFloat {
    150
  }

  override func tableView(
    _ tableView: UITableView,
    cellForRowAt indexPath: IndexPath
  ) -> UITableViewCell {
    let cell =
      tableView.dequeueReusableCell(withIdentifier: "sample")
      ?? UITableViewCell(style: .subtitle, reuseIdentifier: "sample")
    cell.textLabel?.text = page == .showcase
      ? "Showcase space \(indexPath.row + 1)"
      : "Diagnostic sample \(indexPath.row + 1)"
    cell.detailTextLabel?.text = [
      "Orange content",
      "Blue content",
      "Green content",
      "Dark content",
      "Bright detailed content",
    ][indexPath.row % 5]
    cell.textLabel?.font = .preferredFont(forTextStyle: .title2)
    cell.textLabel?.textColor = indexPath.row % 5 == 4 ? .black : .white
    cell.detailTextLabel?.textColor =
      indexPath.row % 5 == 4 ? .darkGray : .white.withAlphaComponent(0.74)
    cell.backgroundColor = colors[indexPath.row % colors.count]
    cell.layer.cornerCurve = .continuous
    cell.layer.cornerRadius = 24
    cell.clipsToBounds = true
    cell.selectionStyle = .none
    return cell
  }
}
