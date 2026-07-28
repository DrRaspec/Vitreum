<p align="center">
  <img src="doc/assets/vitreum-logo.svg" alt="Vitreum logo" width="132" />
</p>

<h1 align="center">Vitreum</h1>

<p align="center">
  <strong>Adaptive native and simulated glass surfaces for Flutter.</strong>
</p>

<p align="center">
  <img alt="Version 0.1.0" src="https://img.shields.io/badge/version-0.1.0-7C83FF" />
  <img alt="Flutter 3.35+" src="https://img.shields.io/badge/Flutter-3.35%2B-54C5F8?logo=flutter&logoColor=white" />
  <img alt="Platforms iOS and Android" src="https://img.shields.io/badge/platforms-iOS%20%7C%20Android-101526" />
  <img alt="MIT license" src="https://img.shields.io/badge/license-MIT-6DD5B5" />
</p>

<p align="center">
  Vitreum uses Apple's native Liquid Glass APIs on supported iOS versions and a
  custom Flutter-rendered approximation on other platforms.
</p>

<p align="center">
  <img src="doc/assets/vitreum-showcase-ios26.png" alt="Vitreum's Cupertino showcase using one scoped native glass overlay on iOS 26" width="420" />
</p>

<p align="center"><em>Actual iOS 26.5 simulator capture—not concept artwork. Glass is reserved for the control and navigation layer.</em></p>

## Why Vitreum

Vitreum gives Flutter applications one stable API for small, adaptive glass
surfaces. It chooses the safest available renderer at runtime and falls back
without crashing when native composition, shaders, or transparency are
unavailable.

- **Adaptive rendering** — native iOS, simulated Flutter, or solid fallback.
- **Honest platform behavior** — Android uses a custom approximation, never
  Apple's native effect.
- **Accessibility first** — reduced transparency and high contrast select a
  more opaque surface.
- **Bounded performance cost** — effects are clipped to their actual surface.
- **Composable widgets** — surfaces, buttons, bars, and grouped backdrops.
- **Safe failure behavior** — unsupported platforms receive a readable fallback.

> [!IMPORTANT]
> One bounded iOS 26 platform-view overlay passed the animated, high-contrast
> simulator diagnostic. Multiple independent native surfaces corrupted Flutter
> composition, so the generic `VitreumGlass` API and automatic mode remain
> simulated. Native use is isolated in `VitreumNativeGlassOverlay`. See the
> evidence and exact scope in the
> [native composition note](doc/native_composition_spike.md).

Vitreum is not affiliated with or endorsed by Apple.

## Native tab-bar preview

The native tab-bar reference is separate from Vitreum's simulated Flutter
navigation. These are real iOS 26.5 simulator captures:

| System UIKit content | System bar with Flutter content | Vitreum simulated |
|---|---|---|
| <img src="doc/assets/system-uitabbarcontroller-native.png" alt="Native UITabBarController with UIKit content" width="240" /> | <img src="doc/assets/system-uitabbarcontroller-flutter.png" alt="Native UITabBarController with Flutter content" width="240" /> | <img src="doc/assets/vitreum-simulated-tabbar-comparison.png" alt="Vitreum simulated navigation" width="240" /> |

The first two use Apple's actual `UITabBarController`; the third is the
cross-platform Flutter approximation. See the
[complete native integration guide](doc/native_tab_scaffold.md) or browse the
[documentation index](doc/README.md).

## Compatibility

| Platform                | Renderer                                   | Current status                                           |
| ----------------------- | ------------------------------------------ | -------------------------------------------------------- |
| iOS 26+                 | Flutter default; scoped native overlay     | One native overlay validated; multiple views failed      |
| iOS 13–25               | Flutter simulation                         | Supported                                                |
| Android 5.0+            | Flutter simulation                         | Original approximation; never presented as Apple's glass |
| Other Flutter platforms | Solid/translucent surface                  | Safe fallback                                            |

## Installation

Add Vitreum to `pubspec.yaml`:

```yaml
dependencies:
  vitreum: ^0.1.0
```

Then fetch dependencies:

```sh
flutter pub get
```

## Quick start

```dart
import 'package:flutter/material.dart';
import 'package:vitreum/vitreum.dart';

class GlassCard extends StatelessWidget {
  const GlassCard({super.key});

  @override
  Widget build(BuildContext context) {
    return const VitreumGlass(
      shape: VitreumShape.roundedRectangle(radius: 24),
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Balance', style: TextStyle(fontSize: 14)),
            SizedBox(height: 8),
            Text(
              r'$2,345.67',
              style: TextStyle(fontSize: 32, fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }
}
```

The effect is painted behind `child`; layout, semantics, and child interaction
continue to behave like normal Flutter widgets.

### Scoped native iOS overlay

Use this only for one bounded native overlay on a route. It falls back to the
Flutter renderer when its dedicated validation gate is unavailable:

```dart
VitreumNativeGlassOverlay(
  shape: const VitreumShape.capsule(),
  semanticLabel: 'Search',
  child: const Padding(
    padding: EdgeInsets.symmetric(horizontal: 18, vertical: 12),
    child: Text('Search spaces'),
  ),
)
```

Do not create several instances on one route. That topology reproduced
stretched Flutter layers in the iOS 26.5 simulator and is not supported.

## Core widgets

### Glass surface

```dart
VitreumGlass(
  mode: VitreumMode.automatic,
  style: VitreumStyle.regular,
  quality: VitreumQuality.adaptive,
  shape: const VitreumShape.roundedRectangle(radius: 24),
  tint: const Color(0xFF8C9EFF),
  semanticLabel: 'Account summary',
  child: const Padding(
    padding: EdgeInsets.all(20),
    child: Text('Adaptive glass'),
  ),
)
```

### Glass button

```dart
VitreumGlassButton(
  semanticLabel: 'Send payment',
  onPressed: sendPayment,
  child: const Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(Icons.arrow_outward_rounded),
      SizedBox(width: 8),
      Text('Send'),
    ],
  ),
)
```

### Floating navigation bar

`VitreumGlassNavigationBar` is a cross-platform Flutter approximation. It is
not a native iOS `UITabBar` and never presents itself as one:

```dart
VitreumGlassNavigationBar(
  selectedIndex: selectedIndex,
  onDestinationSelected: selectDestination,
  destinations: const [
    VitreumNavigationDestination(
      icon: Icons.auto_awesome,
      label: 'Showcase',
    ),
    VitreumNavigationDestination(
      icon: Icons.speed,
      label: 'Diagnostics',
    ),
  ],
)
```

For the real system behavior, the example iOS host provides
`VitreumNativeTabScaffold`, an actual `UITabBarController` with
`UITabBarItem`s and default system appearance. It requires native host
integration because a native container view controller cannot be installed by
an ordinary Flutter widget. See the
[native tab-bar reference](doc/native_tab_scaffold.md) for the three comparison
modes, FlutterEngineGroup integration, minimization settings, and limitations.

### Grouped surfaces

Use a group for nearby, non-overlapping simulated surfaces that share the same
backdrop:

```dart
VitreumGlassGroup(
  spacing: 12,
  child: Row(
    children: [
      VitreumGlassButton(onPressed: send, child: const Text('Send')),
      const SizedBox(width: 12),
      VitreumGlassButton(onPressed: receive, child: const Text('Receive')),
    ],
  ),
)
```

Grouped backdrop filters should not overlap. Use independent surfaces when each
control requires different backdrop input. `VitreumGlassGroup` always uses the
Flutter simulation, including on iOS 26. Native grouping is not claimed:
Vitreum does not yet expose a single UIKit `UIGlassContainerEffect` hierarchy.

### Interaction and material transitions

`VitreumGlassButton` provides touch-position illumination, restrained press
scale, pointer hover, keyboard focus, cancellation, and reduced-motion
behavior. For independent appearance:

```dart
VitreumGlassTransition(
  type: VitreumTransitionType.materialize,
  visible: isVisible,
  child: const VitreumGlass(
    shape: VitreumShape.capsule(),
    child: Padding(
      padding: EdgeInsets.all(16),
      child: Text('Filters'),
    ),
  ),
)
```

Use `VitreumTransitionType.matchedGeometry` with a shared
`matchedGeometryTag` for route geometry, or `identity` to disable
material-specific motion.

### Minimize a floating bar on scroll

```dart
VitreumGlassBar(
  scrollController: controller,
  minimizeOnScroll: true,
  scrollEdgeTreatment: true,
  child: navigationItems,
)
```

The minimized bar remains visible and restores on upward scrolling or direct
interaction.

## Rendering modes

| Mode        | Behavior                                                    |
| ----------- | ----------------------------------------------------------- |
| `automatic` | Chooses the safest supported backend                        |
| `native`    | Attempts validated native rendering, then falls back safely |
| `simulated` | Always uses the Flutter approximation                       |
| `solid`     | Disables backdrop blur and refraction                       |

Force a predictable low-cost simulation:

```dart
const VitreumGlass(
  mode: VitreumMode.simulated,
  quality: VitreumQuality.low,
  child: Text('Conservative simulated glass'),
)
```

## Runtime capabilities

```dart
final capabilities = await Vitreum.getCapabilities();

debugPrint('Platform: ${capabilities.platform.name}');
debugPrint('Backend: ${capabilities.selectedAutomaticBackend.name}');
debugPrint('Native API: ${capabilities.nativeApiExists}');
debugPrint('Native view: ${capabilities.nativeViewCanBeCreated}');
debugPrint(
  'Flutter backdrop: ${capabilities.nativeBackdropCompositionValidated}',
);
debugPrint(
  'Single overlay: '
  '${capabilities.nativeSingleOverlayCompositionValidated}',
);
debugPrint(
  'Native interaction: ${capabilities.nativeInteractiveEffectAvailable}',
);
debugPrint('Simulation: ${capabilities.simulatedRendererAvailable}');
debugPrint('Shader: ${capabilities.shaderAvailable}');
debugPrint('Reduced transparency: ${capabilities.reducedTransparency}');
```

Capability queries return a defensive fallback instead of throwing when native
plugin registration is unavailable.

## Accessibility

When reduced transparency is reported, Vitreum prefers a nearly opaque solid
surface, disables expensive optical effects, and preserves contrast. Flutter
high-contrast contexts also select solid rendering.

- Give meaningful controls a `semanticLabel`.
- Keep essential text contrast independent of the background.
- Test large text and focus navigation.
- Glass buttons preserve a minimum 48 logical-pixel touch target.
- Press animations respect disabled-animation settings.

## Performance

Glass is a rendering effect, not a free decoration. Profile the actual screen
on representative hardware.

- Keep glass surfaces small and bounded.
- Keep fixed glass controls outside scrolling list rows.
- Prefer `VitreumQuality.low` on dense or performance-sensitive screens.
- Group only non-overlapping surfaces.
- Avoid continuously animating blur radius.
- Measure video and animated backgrounds in profile mode.

Vitreum does not publish unverified FPS claims. The example includes an
adjustable stress test for count, size, quality, blur, refraction request, and
interaction.

## Where not to use Vitreum

- Every row of a long `ListView`
- Large full-screen blur layers
- Video-heavy backgrounds without profiling
- Many overlapping high-quality surfaces
- Essential text without sufficient contrast

## Troubleshooting

<details>
<summary><strong>Native iOS glass is not selected</strong></summary>

Native selection requires all three gates: the iOS API exists, the platform
view can be created, and the requested integration path is
composition-validated. Generic automatic composition is currently marked
failed; only `VitreumNativeGlassOverlay` consults the validated single-overlay
gate. Reduced Transparency, older iOS versions, grouped surfaces, or a failed
gate select the Flutter or solid fallback.

</details>

<details>
<summary><strong>The surface looks solid</strong></summary>

Reduced transparency, high contrast, explicit solid mode, or an unsupported
platform selects the readable solid fallback.

</details>

<details>
<summary><strong>High quality looks like balanced</strong></summary>

The optional refraction shader is not enabled in 0.1.0. High quality safely
resolves to balanced when shader support is unavailable.

</details>

<details>
<summary><strong>Scrolling becomes expensive</strong></summary>

Reduce surface size and count, select low quality, and avoid placing glass in
individual list rows.

</details>

## Example and development

The [example application](example/README.md) separates a polished Cupertino
showcase from a diagnostics page containing exact capability values, three
composition scenes, and a configurable stress test.

See the [native-versus-simulated visual validation](doc/visual_validation.md)
for real captures, evaluation criteria, and known differences.
Selected interaction timings and quality degradation are documented in
[behavior.md](doc/behavior.md).

Contributions are welcome. Read [CONTRIBUTING.md](CONTRIBUTING.md), then run:

```sh
flutter pub get
dart format .
flutter analyze
flutter test
```

## License

Vitreum is available under the [MIT License](LICENSE).
