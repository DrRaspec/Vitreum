# Customization reference

Vitreum keeps production-oriented defaults while allowing local or
application-wide customization. This guide separates portable controls from
settings that apply only to Flutter-rendered fallbacks.

## Resolution order

Vitreum resolves appearance in this order:

1. A value explicitly supplied to the widget.
2. The nearest `VitreumTheme` inherited widget.
3. `VitreumThemeData` installed in `ThemeData.extensions`.
4. Vitreum's built-in defaults.

`VitreumTheme` is suitable for every Flutter app and takes precedence over the
Material theme extension. It is the recommended package-wide integration for
`CupertinoApp`.

```dart
CupertinoApp(
  builder: (context, child) => VitreumTheme(
    data: const VitreumThemeData(
      style: VitreumStyle.clear,
      quality: VitreumQuality.balanced,
      fallbackStyle: VitreumFallbackStyle(
        blurSigma: 18,
        edgeWidth: 1.25,
      ),
    ),
    child: child ?? const SizedBox.shrink(),
  ),
  home: const HomePage(),
)
```

Material applications can install the same data through the normal extension
mechanism:

```dart
MaterialApp(
  theme: ThemeData(
    extensions: const <ThemeExtension<dynamic>>[
      VitreumThemeData(
        style: VitreumStyle.clear,
        quality: VitreumQuality.balanced,
      ),
    ],
  ),
  home: const HomePage(),
)
```

## Backend support

| Control | Native iOS | Simulated Flutter | Solid fallback |
|---|:---:|:---:|:---:|
| `style` | Yes | Yes | No optical effect |
| `shape` and radius | Yes | Yes | Yes |
| `tint` | Yes | Yes | Yes |
| `inheritTint` | Yes | Yes | Yes |
| `interactive` | Yes when supported | Yes | No optical effect |
| `clipBehavior` for Flutter child | Yes | Yes | Yes |
| `quality` | Fallback selection only | Yes | No |
| `blurSigma` | System-owned | Yes | No |
| `surfaceOpacity` | System-owned | Yes | No; fixed readable opacity |
| Refraction and chromatic separation | System-owned | High quality only | No |
| Highlight and edge controls | System-owned | Yes | No |
| Shadow controls | System-owned | Yes | No |

The native renderer intentionally exposes only Apple's public `UIGlassEffect`
controls. Vitreum does not simulate unsupported native parameters or claim
pixel parity between backends.

Compiling the iOS plugin requires Xcode 26 and the iOS 26 SDK because the
source references `UIGlassEffect`. The deployment target remains iOS 13;
runtime capability checks keep iOS 13–25 on simulated glass.

When a package theme supplies a tint, set `inheritTint: false` on an individual
surface to request no explicit tint. This distinction matters on native iOS,
where a null system tint is not the same configuration as a transparent tint.

## Child clipping

All public glass widgets default to `Clip.antiAlias`. The Flutter child is
clipped using the same `VitreumShape` as the glass, including on the native
platform-view path. This keeps text selection, input decoration, ink, images,
and other child painting inside the visible surface.

```dart
VitreumNativeGlassOverlay(
  style: VitreumStyle.clear,
  shape: const VitreumShape.capsule(),
  child: const TextField(
    maxLines: 3,
    decoration: InputDecoration(
      hintText: 'Type a message',
      border: InputBorder.none,
    ),
  ),
)
```

Use `Clip.hardEdge` when performance is more important than an antialiased
boundary. Use `Clip.none` only for intentional child overflow. The glass layer
itself always remains bounded to its shape.

## Simulated fallback style

`VitreumFallbackStyle` is validated before painting. Non-finite values use the
documented default and finite values are clamped to these safe ranges:

| Property | Default | Safe range | Effect |
|---|---:|---:|---|
| `blurSigma` | 14 | 0–40 | Backdrop blur request; renderer tiers apply tighter limits |
| `surfaceOpacity` | 0.16 | 0–1 | Base tint-surface opacity |
| `refractionStrength` | 0.04 | 0–0.2 | High-quality edge displacement request |
| `chromaticAberration` | 0.008 | 0–0.05 | High-quality spectral separation request |
| `highlightStrength` | 0.22 | 0–1 | Directional surface highlight |
| `borderOpacity` | 0.28 | 0–1 | Edge-light opacity multiplier |
| `edgeWidth` | 1 | 0–8 | Edge-light stroke width; zero disables it |
| `edgeColor` | White | Any color | Edge-light base color and alpha |
| `shadowStrength` | 0.16 | 0–1 | Ambient-shadow opacity multiplier |
| `shadowBlurSigma` | 8 | 0–40 | Ambient-shadow softness |
| `shadowOffset` | `(0, 3)` | −40–40 per axis | Ambient-shadow displacement |
| `shadowColor` | Black | Any color | Ambient-shadow base color and alpha |

These are simulation parameters, not measurements or constants copied from
Apple. The solid accessibility fallback uses only the resolved tint and ignores
surface opacity, blur, refraction, highlight, edge, and shadow parameters.

## Button interaction style

`VitreumInteractionStyle` can be supplied to `VitreumGlassButton` or installed
through `VitreumThemeData`.

| Property | Default | Validated range |
|---|---:|---:|
| `pressedScale` | 0.975 | 0.8–1.2 |
| `duration` | 120 ms | 0–2 s; invalid values restore the default |
| `curve` | `easeOutCubic` | Any Flutter curve |
| `pressedHighlightBoost` | 0.12 | 0–1 |
| `pressedShadowFactor` | 0.76 | 0–1 |
| `minimumSize` | 48 × 48 | 0–400 per axis |

The package permits smaller custom targets for specialized layouts, but
applications remain responsible for platform accessibility guidance.
Disabled animations replace press scaling with an immediate, unscaled state.

## Navigation-bar style

`VitreumNavigationBarStyle` controls the Flutter-owned destination layout for
both navigation widgets without changing selection semantics or callbacks.

| Property | Default |
|---|---:|
| `height` | 64 |
| `horizontalPadding` | 8 |
| `destinationMinWidth` | 88 |
| `destinationMinHeight` | 44 |
| `indicatorSize` | 36 |
| `iconSize` | 24 |
| `itemSpacing` | 6 |
| `labelFontSize` | 13 |
| `selectedColor` | 94% white |
| `unselectedColor` | 58% white |
| `indicatorColor` | 5% white |
| `pressedIndicatorColor` | 10% white |

Finite layout values are clamped to non-negative renderer-safe ranges.
Customize `shape`, `tint`, and `clipBehavior` directly on
`VitreumGlassNavigationBar` or `VitreumNativeGlassNavigationBar`.

Choose `VitreumGlassNavigationBar` for a portable simulated surface with a
solid accessibility fallback.
Choose `VitreumNativeGlassNavigationBar` when one navigation bar on the route
should use the validated native iOS glass path. The latter uses Apple's public
`UIGlassEffect` on supported iOS 26 devices and automatically falls back to the
simulated renderer elsewhere. Both widgets keep their destinations and
interaction in Flutter; neither is a UIKit `UITabBar`.

Both navigation widgets also accept `scrollController`, `minimizeOnScroll`,
`scrollEdgeTreatment`, `expandOnInteraction`, `minimizedTranslation`, and
`minimizedScale`. Minimization is disabled by default for compatibility.
Reversed vertical lists are detected automatically; callers should not invert
their controller offsets manually.

## Scroll-minimization configuration

`VitreumGlassBar`, `VitreumGlassNavigationBar`, and
`VitreumNativeGlassNavigationBar` share these controls:

| Property | Default | Behavior |
|---|---:|---|
| `scrollController` | `null` | One vertical scroll source; unattached or multiply attached controllers are ignored safely |
| `minimizeOnScroll` | `false` | Enables user-scroll-driven compact and expanded states |
| `scrollEdgeTreatment` | `false` | Strengthens simulated separation after content moves beneath the bar |
| `expandOnInteraction` | `true` | Pointer-down expands before the child handles the same interaction |
| `minimizedTranslation` | `Offset.zero` | Fractional compact-state translation; zero preserves caller-owned safe-area placement |
| `minimizedScale` | `0.9` | Compact-state scale; non-finite values restore `0.9`, finite values clamp to 0.5–1 |

Minimization uses 28 logical pixels of sustained screen-wise downward movement
and expansion uses 16 logical pixels upward. These thresholds are intentionally
not public configuration: consistent hysteresis avoids per-screen behavior
drift and rapid toggling. Idle or programmatic scroll changes do not minimize,
while reaching the controller's initial edge restores the expanded state.

## Native-overlay boundary

Use at most one native overlay per route. A
`VitreumNativeGlassNavigationBar` counts as that overlay and must not share a
route with another `VitreumNativeGlassOverlay`. Multiple independent UIKit
platform views are outside the validated composition topology and can produce
missing, split, or stretched Flutter layers. Use `VitreumGlass` or one composed
native overlay when multiple controls are required.

Native optical edges are rendered by iOS. If diagnosing a small edge line,
compare against `VitreumGlass(mode: VitreumMode.simulated, ...)`; simulated
edge lighting can be disabled with `edgeWidth: 0` or `borderOpacity: 0`.

## Updating an existing application

Version 0.2.0 changes `style`, `quality`, and `fallbackStyle` fields on themed
widgets from non-null to nullable. A null value represents theme inheritance.
Existing constructor call sites remain valid, but code that reads those fields
directly must handle null or resolve the value from `VitreumThemeData.of`.

Flutter children are now clipped to their glass shape on the native path,
matching the existing simulated and solid behavior. Set
`clipBehavior: Clip.none` to retain intentional child overflow.

The default compact transform for `VitreumGlassBar` also changed from a
hard-coded 86% scale with `Offset(0, 0.18)` translation to a configurable 90%
scale with zero translation. This keeps externally applied safe-area spacing
stable. To retain the previous appearance, pass:

```dart
VitreumGlassBar(
  minimizedScale: 0.86,
  minimizedTranslation: const Offset(0, 0.18),
  child: child,
)
```
