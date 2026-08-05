# Visual validation

Vitreum's portable renderer is an original Flutter approximation. It targets
observable behavior in Apple's public guidance; it does not claim Apple's
private shader formula, numerical constants, or pixel-identical output.

Authoritative references:

- [Liquid Glass overview](https://developer.apple.com/documentation/technologyoverviews/liquid-glass)
- [Human Interface Guidelines — Materials](https://developer.apple.com/design/human-interface-guidelines/materials)
- [Human Interface Guidelines — Layout](https://developer.apple.com/design/human-interface-guidelines/layout)
- [Human Interface Guidelines — Toolbars](https://developer.apple.com/design/human-interface-guidelines/toolbars)
- [Human Interface Guidelines — Tab bars](https://developer.apple.com/design/human-interface-guidelines/tab-bars)
- [Adopting Liquid Glass](https://developer.apple.com/documentation/technologyoverviews/adopting-liquid-glass)
- [Applying Liquid Glass to custom views](https://developer.apple.com/documentation/swiftui/applying-liquid-glass-to-custom-views)
- [GlassEffectContainer](https://developer.apple.com/documentation/swiftui/glasseffectcontainer)
- [Landmarks: Building an app with Liquid Glass](https://developer.apple.com/documentation/swiftui/landmarks-building-an-app-with-liquid-glass)
- [Meet Liquid Glass](https://developer.apple.com/videos/play/wwdc2025/219/)
- [Get to know the new design system](https://developer.apple.com/videos/play/wwdc2025/356/)
- [Build a UIKit app with the new design](https://developer.apple.com/videos/play/wwdc2025/284/)

## Controlled iOS 26.5 captures

All three scenes use an iPhone 17 Pro Max simulator and moving,
high-contrast content. Labels are embedded in the scenes so the renderer
cannot be confused.

| Pure native UIKit | Native over Flutter | Flutter simulated |
|---|---|---|
| ![Pure native UIKit diagnostic](https://raw.githubusercontent.com/DrRaspec/Vitreum/main/doc/assets/diagnostic-pure-native.png) | ![Native glass over Flutter diagnostic](https://raw.githubusercontent.com/DrRaspec/Vitreum/main/doc/assets/diagnostic-native-over-flutter.png) | ![Flutter simulated diagnostic](https://raw.githubusercontent.com/DrRaspec/Vitreum/main/doc/assets/diagnostic-flutter-simulated.png) |

The first scene keeps the animated gradient, stripes, text, and
`UIVisualEffectView` in one native hierarchy. The second places the same native
effect above a Flutter gradient, checkerboard, reference lines, moving text,
and frame counter. The third keeps that Flutter background and substitutes
Vitreum's simulated renderer.

The native-over-Flutter capture shows spatially correct, bounded sampling of
the grid and diagonal lines. A second capture at another frame confirmed the
background phase and moving text changed while the effect remained correctly
mapped. No repeated, stretched, black, or stale backdrop fragment appeared.
This validates one bounded overlay only. Two independent native glass platform
views on the showcase later reproduced malformed Flutter layers, so automatic
and generic `VitreumGlass` rendering remain simulated.

## Floating showcase captures

These iPhone 17 Pro Max simulator captures exercise the corrected floating
composition. The simulated bar is fixed above the safe area while the orange
and blue cards move underneath it. The final capture uses the separately gated,
single native overlay topology described above.

| Simulated: search and orange | Simulated: blue after scroll | Diagnostics selected | Validated native overlay |
|---|---|---|---|
| ![Simulated search and navigation over orange content](https://raw.githubusercontent.com/DrRaspec/Vitreum/main/doc/assets/showcase-simulated-top-orange.png) | ![Simulated navigation over blue content after scrolling](https://raw.githubusercontent.com/DrRaspec/Vitreum/main/doc/assets/showcase-simulated-nav-blue.png) | ![Diagnostics destination selected](https://raw.githubusercontent.com/DrRaspec/Vitreum/main/doc/assets/showcase-diagnostics-selected.png) | ![Single validated native navigation overlay](https://raw.githubusercontent.com/DrRaspec/Vitreum/main/doc/assets/showcase-native-single-overlay.png) |

## System tab-bar reference

The custom glass capsule above is not a native tab bar. The example Runner now
contains a separate `VitreumNativeTabScaffold` implemented with an actual,
unmodified `UITabBarController`.

| System UIKit content | System tab bar with Flutter content | Vitreum simulated comparison |
|---|---|---|
| ![UITabBarController with native scrolling content](https://raw.githubusercontent.com/DrRaspec/Vitreum/main/doc/assets/system-uitabbarcontroller-native.png) | ![UITabBarController hosting FlutterEngineGroup pages](https://raw.githubusercontent.com/DrRaspec/Vitreum/main/doc/assets/system-uitabbarcontroller-flutter.png) | ![Cross-platform Vitreum simulated tab bar](https://raw.githubusercontent.com/DrRaspec/Vitreum/main/doc/assets/vitreum-simulated-tabbar-comparison.png) |

Recordings:

- [System selection, minimization, expansion, and backdrop validation](https://raw.githubusercontent.com/DrRaspec/Vitreum/main/doc/assets/system-uitabbarcontroller-selection-scroll.mp4)
- [Vitreum simulated selection and scrolling comparison](https://raw.githubusercontent.com/DrRaspec/Vitreum/main/doc/assets/vitreum-simulated-tabbar-comparison.mp4)

## Observable comparison

| Characteristic | Native reference | Simulated renderer |
|---|---|---|
| Functional layer | Controls float above edge-to-edge content | Example restricts glass to controls and navigation |
| Background response | Native material adapts to content underneath | Bounded backdrop blur and restrained separation |
| Lensing | Native environmental lensing around geometry | Small edge-weighted displacement with a stable center |
| Edge light | Nonuniform, contextual illumination | Partial sweep highlight, not a uniform bright outline |
| Tint | `nil` by default; explicit tint only | Low-opacity tint; clear style reduces it further |
| Legibility | Native regular material adaptation | Theme-aware separation plus solid accessibility fallback |
| Interaction | Native effect supports interaction | Scale and touch-position illumination in Flutter |
| Grouping | Requires one native glass container hierarchy | Shared Flutter backdrop; native morphing is not claimed |

## Known differences

- Flutter cannot reproduce Apple's private adaptive material or exact
  environmental lighting.
- Related simulated surfaces can coordinate backdrop and motion but do not
  perform native geometric merging.
- The optional high-quality filter uses restrained local samples; unsupported
  renderers use bounded blur.
- Foreground text and glyph colors do not automatically flip from sampled
  backdrop luminance.
- Native validation currently covers one bounded iOS 26.5 simulator overlay.
  Multiple independent native glass platform views failed composition and are
  unsupported.
