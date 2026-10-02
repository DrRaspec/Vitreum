# Changelog

## 0.2.0 - 2026-08-05

### Breaking change

- `style`, `quality`, and `fallbackStyle` fields on themed widgets are now
  nullable. A null value means “inherit from `VitreumThemeData`.” Constructor
  call sites remain compatible, but code that reads these fields directly must
  handle null.
- Raised the declared Flutter minimum to 3.44 so it matches the existing Dart
  3.12.1 language constraint instead of advertising an impossible toolchain
  combination.
- Documented Xcode 26 and the iOS 26 SDK as iOS build requirements; the runtime
  deployment target remains iOS 13 with simulation on iOS 13–25.

### Added and fixed

- Added `VitreumNativeGlassNavigationBar` for Flutter-owned navigation over one
  native iOS 26 `UIGlassEffect` surface, with automatic simulated fallback on
  unsupported or unvalidated environments.
- Added shared, reverse-aware scroll minimization to `VitreumGlassBar`,
  `VitreumGlassNavigationBar`, and `VitreumNativeGlassNavigationBar`, including
  interaction expansion control, movement hysteresis, safe listener lifecycle,
  and protection from idle or keyboard-driven offset changes.
- Changed the default minimized transform from a hard-coded 86% scale and
  downward translation to a configurable 90% scale with zero translation,
  preserving caller-owned safe-area spacing. The former values remain
  available through explicit configuration.
- Added consistent shape-aware Flutter child clipping across native, simulated,
  and solid glass surfaces, with configurable `clipBehavior`.
- Added simulated edge width/color and shadow blur/offset/color controls.
- Added package-wide defaults through the `VitreumThemeData` theme extension.
- Added `VitreumInteractionStyle` for button feedback and target sizing.
- Added `VitreumNavigationBarStyle` plus configurable navigation shape and tint.
- Added Material theme-extension and Cupertino-compatible inherited-theme
  integration with per-widget override precedence.
- Added `inheritTint` so individual surfaces can opt out of a package-wide
  theme tint without substituting a transparent native tint.
- Fixed themed high-quality buttons so pointer tracking matches an explicitly
  configured high-quality button.
- Corrected stale CocoaPods homepage, author, and version metadata.
- Migrated the Android plugin to Flutter 3.44's built-in Kotlin configuration.

## 0.1.2

- Added repository and issue tracker metadata so pub.dev links users to GitHub.
- Changed README assets and documentation links to absolute GitHub URLs so they
  render and remain navigable on pub.dev.

## 0.1.1

- Added a prominent widget preview gallery to the package README using real
  iOS simulator captures.

## 0.1.0

- Added immutable surface, shape, quality, mode, fallback, and capability APIs.
- Added bounded Flutter simulation, solid fallback, buttons, bars, and grouping.
- Added Android/iOS capability channels and guarded public iOS 26 glass code.
- Added explicit native API, view creation, backdrop validation, interactive
  effect, and simulated-renderer capability fields.
- Added an example, tests, accessibility guidance, and performance guidance.
- Added professional package branding, UI preview artwork, and expanded
  production-focused documentation.
- Reworked simulated glass around Apple-documented observable behavior:
  edge-weighted lensing, partial highlights, restrained tint, cached optional
  Impeller shader filtering, and touch illumination.
- Added pure-native, native-over-Flutter, and simulated animated diagnostic
  scenes with real iOS 26.5 captures.
- Validated one bounded native overlay on the iOS 26.5 simulator, reproduced
  corruption with multiple independent platform views, and kept generic
  automatic rendering simulated.
- Added the explicitly scoped `VitreumNativeGlassOverlay` API and a separate
  single-overlay validation capability.
- Rebuilt the example as separate Cupertino showcase and diagnostics pages.
- Kept grouped surfaces on the simulated path until one native
  `UIGlassContainerEffect` hierarchy is implemented and validated.
- Added touch-position illumination, pointer/focus feedback, reduced-motion
  handling, group proximity blending, material transition primitives, and
  scroll-aware bar minimization.
- Split the Flutter `VitreumGlassNavigationBar` approximation from the example
  Runner's real `VitreumNativeTabScaffold` system reference.
- Added native-content and FlutterEngineGroup `UITabBarController` comparison
  modes, iOS 26 minimize settings, XCTest coverage, and simulator recordings.
