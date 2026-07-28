# Vitreum documentation

## Visual overview

| Native system tabs | Native tabs with Flutter pages | Simulated Flutter navigation |
|---|---|---|
| ![Native UIKit tab reference](assets/system-uitabbarcontroller-native.png) | ![Native tab controller with Flutter content](assets/system-uitabbarcontroller-flutter.png) | ![Simulated Vitreum navigation](assets/vitreum-simulated-tabbar-comparison.png) |

## Guides

| Document | Contents |
|---|---|
| [Native iOS tab-bar integration](native_tab_scaffold.md) | Architecture, complete host integration, FlutterEngineGroup lifecycle, method-channel contract, minimization, accessibility, migration, testing, troubleshooting, previews, and recordings |
| [Native glass composition](native_composition_spike.md) | Platform-view topology, validated scope, failure analysis, runtime gating, and production validation requirements |
| [Visual validation](visual_validation.md) | Real simulator captures, native/simulated comparison, observable differences, and known limitations |
| [Interaction and motion](behavior.md) | Timings, press feedback, quality degradation, grouping, scrolling, and backdrop validation |
| [Performance diagnostics](performance_debugging.md) | Live FPS/build/raster/jank overlay, frame budgets, profiling procedure, interpretation, and platform limitations |

## Start here

- Building an ordinary Flutter interface: read the root [README](../README.md).
- Requiring Apple's actual system tab bar: read
  [Native iOS tab-bar integration](native_tab_scaffold.md).
- Evaluating native platform-view glass: read
  [Native glass composition](native_composition_spike.md).
- Reviewing screenshots and recordings: read
  [Visual validation](visual_validation.md).

Vitreum distinguishes verified behavior from approximations. A native system
container, a native glass platform view, and a Flutter-rendered glass surface
have different ownership, lifecycle, and composition guarantees.
