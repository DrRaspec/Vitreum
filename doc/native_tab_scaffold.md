# Native iOS tab-bar integration

This guide documents the complete separation between Vitreum's portable
Flutter navigation and the example application's real iOS system tab bar.

## Preview

These are actual iPhone 17 Pro Max, iOS 26.5 simulator captures produced with
Xcode 26.6.

| System UIKit content | System bar with Flutter content | Vitreum simulated |
|---|---|---|
| ![UITabBarController with native UIKit scrolling content](https://raw.githubusercontent.com/DrRaspec/Vitreum/main/doc/assets/system-uitabbarcontroller-native.png) | ![UITabBarController hosting FlutterEngineGroup content](https://raw.githubusercontent.com/DrRaspec/Vitreum/main/doc/assets/system-uitabbarcontroller-flutter.png) | ![Vitreum simulated Flutter navigation](https://raw.githubusercontent.com/DrRaspec/Vitreum/main/doc/assets/vitreum-simulated-tabbar-comparison.png) |
| Actual `UITabBarController` | Actual `UITabBarController` | Flutter approximation |

Recordings:

- [System selection, scroll-down minimization, scroll-up expansion, and colorful backdrop validation](https://raw.githubusercontent.com/DrRaspec/Vitreum/main/doc/assets/system-uitabbarcontroller-selection-scroll.mp4)
- [Vitreum simulated selection and scrolling comparison](https://raw.githubusercontent.com/DrRaspec/Vitreum/main/doc/assets/vitreum-simulated-tabbar-comparison.mp4)

## Choose the correct component

| Requirement | Use |
|---|---|
| Apple's actual tab-bar layout and material | `VitreumNativeTabScaffold` |
| Native `UITabBarItem` semantics and selection | `VitreumNativeTabScaffold` |
| iOS 26 `UITabBarController.MinimizeBehavior` | `VitreumNativeTabScaffold` |
| Android, older iOS, web, or desktop | `VitreumGlassNavigationBar` |
| Navigation inside an ordinary Flutter widget tree | `VitreumGlassNavigationBar` |
| Identical cross-platform application-controlled layout | `VitreumGlassNavigationBar` |

The two implementations are intentionally separate APIs. A caller must choose
one; Vitreum does not silently substitute a custom capsule for a native
`UITabBar`.

## Architecture

### `VitreumNativeTabScaffold`

The example Runner's
[`VitreumNativeTabScaffold.swift`](../example/ios/Runner/VitreumNativeTabScaffold.swift)
subclasses Apple's `UITabBarController`.

It creates two system items:

| Destination | Normal SF Symbol | Selected SF Symbol |
|---|---|---|
| Showcase | `sparkles` | `sparkles` |
| Diagnostics | `gauge.with.dots.needle.67percent` | `gauge.with.dots.needle.100percent` |

The system owns:

- tab-bar shape, material, blur, and Liquid Glass treatment;
- destination spacing, label placement, and selection animation;
- selected and unselected vibrancy;
- hit testing, accessibility roles, and selected state;
- safe-area placement and orientation layout;
- iOS 26 minimization and expansion.

The implementation does **not** create a `UITabBarAppearance`, background
image, shadow image, custom blur, mask, corner radius, fixed height, item
offset, label font, selected background, selection indicator, or opacity
wrapper.

### `VitreumGlassNavigationBar`

[`VitreumGlassNavigationBar`](../lib/src/widgets/vitreum_glass_navigation_bar.dart)
is a Flutter-rendered approximation. It always requests
`VitreumMode.simulated`.

It:

- works inside a normal Flutter widget tree;
- supports Android and portable fallback use;
- owns its Flutter icon, text, touch, and animation layout;
- does not instantiate `UITabBar` or `UITabBarController`;
- does not claim Apple's native tab-bar behavior.

## Why native host integration is required

`UITabBarController` is a container view controller, not a visual effect. It
must own the destination view controllers and participate in the UIKit
controller hierarchy.

A Dart widget can create pixels and platform views inside a
`FlutterViewController`, but it cannot replace its native parent with a
`UITabBarController`. The installation therefore belongs in the iOS Runner or
another native host application.

Using a `UiKitView` containing only a standalone `UITabBar` would not provide
the complete controller-managed behavior, content layout guides, child
controller ownership, accessories, or reliable minimization.

## Included comparison modes

The example exposes **Diagnostics → Tab Bar Comparison**:

1. **System native tab bar**
   - Actual `UITabBarController`.
   - Native scrolling `UITableViewController` pages.
   - Authoritative selection and minimization reference.
2. **Native tab bar with Flutter content**
   - Actual `UITabBarController`.
   - Two `FlutterViewController` pages created by `FlutterEngineGroup`.
   - Validates system-tab ownership with Flutter-rendered destinations.
3. **Vitreum simulated tab bar**
   - Pure Flutter `VitreumGlassNavigationBar`.
   - Portable comparison and fallback.

Each mode displays an explicit diagnostic label outside the bar:

- `SYSTEM UITABBARCONTROLLER`
- `SYSTEM UITABBAR + FLUTTER CONTENT`
- `VITREUM SIMULATED`

The native reference deliberately contains no floating add button.

## Host integration walkthrough

The example is the runnable reference. Integrating the same topology in another
iOS Runner involves the following steps.

### 1. Add the native controller

Copy or adapt:

```text
example/ios/Runner/VitreumNativeTabScaffold.swift
```

Add it to the Runner target's **Compile Sources** build phase.

The controller accepts:

```swift
VitreumNativeTabScaffold(
  content: .native,                 // or .flutter
  minimizeSetting: .onScrollDown,   // automatic, never, onScrollDown, onScrollUp
  engineGroup: engineGroup
)
```

The `FlutterEngineGroup` argument is retained by the application delegate. The
scaffold retains engines created for its Flutter pages for the lifetime of the
presented controller.

### 2. Create and retain a FlutterEngineGroup

The example's
[`AppDelegate.swift`](../example/ios/Runner/AppDelegate.swift) owns one group:

```swift
private lazy var nativeTabEngineGroup = FlutterEngineGroup(
  name: "dev.vitreum.native-tabs",
  project: nil
)
```

Do not create a new group during every rebuild or tab selection. One group
shares resources across its engines and avoids treating tab selection as an
engine construction event.

### 3. Register plugins for every secondary engine

Each engine created by the group has its own plugin registry:

```swift
let options = FlutterEngineGroupOptions()
options.entrypoint = entrypoint
let engine = engineGroup.makeEngine(with: options)
GeneratedPluginRegistrant.register(with: engine)
```

Plugins with singleton native state or assumptions about one engine require
their own multi-engine audit.

### 4. Provide Dart entrypoints

Secondary entrypoints must be top-level and protected from tree shaking:

```dart
@pragma('vm:entry-point')
void vitreumShowcaseTabMain() {
  runApp(const ShowcaseTabApp());
}

@pragma('vm:entry-point')
void vitreumDiagnosticsTabMain() {
  runApp(const DiagnosticsTabApp());
}
```

The example entrypoints are in
[`example/lib/main.dart`](../example/lib/main.dart).

### 5. Present the native container

The example uses a small application method channel to request presentation
from Flutter. UIKit finds the current presenter and presents the tab scaffold
full screen. The native controller—not Flutter—then owns all destination
controllers.

An application that starts natively can instead install
`VitreumNativeTabScaffold` directly as its window's root view controller.

## Method-channel contract

The example channel is an application integration detail, not a public Vitreum
package API.

Channel:

```text
dev.vitreum/native_tab_scaffold
```

Method:

```text
present
```

Arguments:

| Key | Type | Values | Required |
|---|---|---|---|
| `content` | string | `native`, `flutter` | yes |
| `minimizeBehavior` | string | `automatic`, `never`, `onScrollDown`, `onScrollUp` | no; defaults to `automatic` |
| `automate` | boolean | `true`, `false` | no; diagnostics only |

Errors:

| Code | Meaning |
|---|---|
| `invalid-arguments` | `content` was missing or unsupported |
| `no-presenter` | No active UIKit controller could present the scaffold |

Production applications should define their own navigation contract instead of
depending on this example-only channel name.

## iOS 26 minimization

The setting maps directly to Apple's public API:

```swift
if #available(iOS 26.0, *) {
  tabBarMinimizeBehavior = .onScrollDown
}
```

| Setting | System behavior |
|---|---|
| `automatic` | Uses the platform default |
| `never` | Keeps the bar expanded |
| `onScrollDown` | Minimizes while scrolling down and expands upward |
| `onScrollUp` | Minimizes upward and expands downward; useful for bottom-aligned content |

No minimization animation is reproduced in Flutter or manually applied to the
native bar.

The UIKit pages contain real `UIScrollView` subclasses and are the
authoritative test. Flutter scrollables are rendered and gesture-managed by
Flutter rather than exposed as UIKit `UIScrollView` instances. Therefore:

- the system tab bar and native selection work with Flutter content;
- controller-driven minimization from Flutter scrolling must be retested for
  each Flutter engine and iOS version;
- Vitreum does not claim universal Flutter-scroll minimization.

## Lifecycle and memory

- `VitreumNativeTabScaffold` retains its secondary Flutter engines while it is
  presented.
- Each engine owns a Dart isolate, navigation state, plugin registry, and
  rendering resources.
- Dismissing the scaffold releases the controller and its retained engine
  array when no external references remain.
- Tab selection does not recreate engines.
- The diagnostic automation never rebuilds the system tab bar; it only changes
  the selected index and sample content offset.
- Apps with expensive plugins should measure startup time and memory on
  physical devices before adopting two engines.

## Accessibility

For the native reference:

- `UITabBarItem` supplies the native tab role, title, and selected state;
- UIKit manages focus order, touch targets, Dynamic Type behavior, and
  VoiceOver announcements for the tab items;
- SF Symbols remain template images and participate in system tint/vibrancy;
- no custom overlay intercepts tab-bar hit testing.

For Flutter content:

- semantics inside each page still come from Flutter;
- the containing system tab items remain UIKit accessibility elements;
- application teams must test transitions between UIKit and Flutter semantics
  with VoiceOver enabled.

The simulator build verifies item titles and selected images through XCTest.
A complete physical-device VoiceOver audit remains a release responsibility.

## Safe areas and rotation

The scaffold specifies no custom tab-bar frame or height. UIKit computes the
bar geometry from the device, orientation, and bottom safe area.

The example supports portrait, landscape left, and landscape right in
`Info.plist`. Child controllers use default UIKit rotation support. Flutter
pages receive their viewport and safe-area changes from their
`FlutterViewController`.

Before release, verify:

- portrait and both landscape orientations;
- devices with and without a home indicator;
- keyboard presentation;
- split-view and Stage Manager when supporting iPad;
- route presentation and dismissal during rotation.

## Migration from the earlier custom/native-overlay bar

The removed `preferNativeOverlay` option did not create a native tab bar. It
placed a custom Flutter destination row over a native glass platform view.

Migration choices:

### Stay cross-platform

Remove `preferNativeOverlay` and continue using:

```dart
VitreumGlassNavigationBar(
  selectedIndex: selectedIndex,
  onDestinationSelected: onSelected,
  destinations: destinations,
)
```

This is always simulated and works in the Flutter tree.

### Adopt the system iOS tab bar

Move top-level navigation ownership to the iOS host:

1. Install `VitreumNativeTabScaffold`.
2. Provide native or Flutter child controllers.
3. Create `UITabBarItem`s in Swift.
4. Remove the Flutter bottom bar from those native-hosted routes.
5. Keep `VitreumGlassNavigationBar` for Android and portable modes.

These paths do not have identical lifecycle or navigation-state semantics, so
they should not be hidden behind one boolean backend flag.

## Running the reference

From the package:

```sh
cd example
flutter run
```

Then open **Diagnostics → Tab Bar Comparison**.

Repeatable direct launches:

```sh
# Native UIKit pages
flutter run \
  --dart-define=VITREUM_TAB_REFERENCE=native \
  --dart-define=VITREUM_TAB_MINIMIZE=onScrollDown

# FlutterEngineGroup pages
flutter run \
  --dart-define=VITREUM_TAB_REFERENCE=flutter \
  --dart-define=VITREUM_TAB_MINIMIZE=onScrollDown

# Simulated comparison
flutter run \
  --dart-define=VITREUM_TAB_REFERENCE=simulated
```

`VITREUM_TAB_AUTOMATION=true` enables repeatable capture automation. It is a
diagnostic option and should not be enabled in a production launch.

## Validation matrix

| Check | Result |
|---|---|
| `UITabBarController` owns the native bar | Passed |
| Destinations use `UITabBarItem` | Passed |
| Required SF Symbols load | Passed in iOS 26.5 simulator |
| No custom tab-bar appearance/background/height | Passed by code inspection |
| Native selection | Passed |
| Native UIKit scroll minimization and expansion | Passed; recorded |
| Orange, blue, green, dark, and bright content | Passed; recorded |
| FlutterEngineGroup pages launch | Passed |
| Tab selection with Flutter pages | Passed |
| Flutter scroll drives system minimization | Not universally claimed |
| iOS simulator build | Passed |
| Native XCTest | Passed |
| Flutter analyzer and tests | Passed |
| Physical-device matrix | Not yet completed |
| Full VoiceOver audit | Not yet completed |

## Troubleshooting

### The native comparison button does nothing

- Confirm the application is running on iOS.
- Confirm `AppDelegate` registered
  `dev.vitreum/native_tab_scaffold`.
- Confirm there is an active key window and presenter.
- Check for `MissingPluginException`, `no-presenter`, or
  `invalid-arguments`.

### A Flutter-hosted tab is blank

- Keep the entrypoint top-level.
- Add `@pragma('vm:entry-point')`.
- Match the Swift entrypoint string exactly.
- Register plugins on the secondary engine.
- Inspect plugins that do not support multiple engines.

### The tab bar does not minimize over Flutter scrolling

This can be an integration limitation rather than a styling bug. Confirm
minimization first with the native UIKit mode. Flutter scrolling does not
necessarily present a native `UIScrollView` for `UITabBarController` to track.
Do not recreate the animation manually and label it system behavior.

### The appearance differs from the preview

- Confirm the OS and device class.
- Remove application-wide `UITabBar.appearance()` customization.
- Search for `UITabBarAppearance`, `backgroundImage`, `shadowImage`,
  `selectionIndicatorImage`, transforms, masks, and opacity.
- Compare with the native UIKit mode before debugging Flutter content.

### Selection or accessibility behaves incorrectly

- Assign the title and images to `UITabBarItem`.
- Do not cover the bar with a Flutter or UIKit gesture overlay.
- Ensure the selected child controller is owned by the tab controller.
- Test with VoiceOver and larger accessibility text sizes.

## Known limitations

- `VitreumNativeTabScaffold` is example-host code, not a Dart widget.
- Applications must design their own cross-platform navigation-state bridge.
- Multiple Flutter engines increase memory and plugin complexity.
- Flutter scrolling may not drive native minimization.
- The recorded validation uses an iOS simulator; physical-device testing is
  still required.
- System Liquid Glass appearance can change between iOS releases because UIKit,
  not Vitreum, renders it.

## Related documentation

- [Documentation index](README.md)
- [Visual validation](visual_validation.md)
- [Native glass composition diagnostic](native_composition_spike.md)
- [Interaction and motion behavior](behavior.md)
