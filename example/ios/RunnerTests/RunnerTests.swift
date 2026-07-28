import Flutter
import UIKit
import XCTest
@testable import Runner

class RunnerTests: XCTestCase {

  func testNativeTabScaffoldUsesSystemTabItems() {
    let group = FlutterEngineGroup(name: "tests", project: nil)
    let tabs = VitreumNativeTabScaffold(
      content: .native,
      minimizeSetting: .onScrollDown,
      engineGroup: group,
      automate: false
    )

    XCTAssertTrue(type(of: tabs) == VitreumNativeTabScaffold.self)
    XCTAssertEqual(tabs.viewControllers?.count, 2)
    XCTAssertEqual(tabs.viewControllers?[0].tabBarItem.title, "Showcase")
    XCTAssertEqual(tabs.viewControllers?[1].tabBarItem.title, "Diagnostics")
    XCTAssertNotNil(tabs.viewControllers?[0].tabBarItem.image)
    XCTAssertNotNil(tabs.viewControllers?[1].tabBarItem.selectedImage)
    if #available(iOS 26.0, *) {
      XCTAssertEqual(tabs.tabBarMinimizeBehavior, .onScrollDown)
    }
  }
}
