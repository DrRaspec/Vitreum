# Performance diagnostics

Vitreum includes an opt-in overlay for inspecting live Flutter frame timing on
iOS and Android. It is disabled by default and does not collect timings until
`enabled` becomes `true`.

## Quick preview

Run the example in profile mode:

```sh
cd example
flutter run --profile \
  --dart-define=VITREUM_PERFORMANCE_OVERLAY=true
```

The same switch covers ordinary example routes and each Flutter page hosted by
the native iOS tab controller. Pure UIKit pages cannot contain a Flutter
overlay; inspect those with Xcode Instruments.

Do not use debug-mode results for performance decisions. Debug builds include
assertions, service extensions, and development overhead that materially
distort frame timing.

## Application integration

Wrap the route or application being measured:

```dart
VitreumPerformanceOverlay(
  enabled: const bool.fromEnvironment('VITREUM_PERFORMANCE_OVERLAY'),
  label: 'catalog · simulated · balanced · 12 cards',
  child: const MyApp(),
)
```

The `label` is optional diagnostic context. Include the route, Vitreum mode,
quality, and surface count so screenshots and recordings remain interpretable.

The overlay ignores pointer input and stays inside the device safe area.
Disabling it removes the timing callback, timer, retained samples, and panel.

## Metrics

| Metric | Meaning |
|---|---|
| FPS | Approximate rendered frames per second across the rolling window |
| Frame avg | Average time from engine vsync to raster completion |
| Build | Average and maximum UI-thread build duration |
| Raster | Average and maximum raster-thread duration |
| Jank | Frames where build or raster exceeded the configured budget |
| Cache | Latest layer and picture raster-cache image data |
| Budget | Threshold used to classify janky frames |

FPS reflects frames that Flutter actually renders. Evaluate it while the target
animation, scrolling, or interaction is active. An idle screen intentionally
does not render continuously, so a low idle FPS is not evidence of poor
performance.

`Cache` is not total application memory. Use Flutter DevTools and platform
profilers for Dart heap, native heap, GPU allocation, CPU, energy, and thermal
analysis.

## Refresh rate targets

The default budget is 16.67 ms for 60 Hz.

| Target | Approximate budget |
|---|---|
| 60 Hz | 16.67 ms |
| 90 Hz | 11.11 ms |
| 120 Hz | 8.33 ms |

For a 120 Hz evaluation:

```dart
VitreumPerformanceOverlay(
  enabled: true,
  frameBudget: const Duration(microseconds: 8333),
  child: const MyApp(),
)
```

A device may dynamically change refresh rate. The overlay deliberately uses an
explicit budget so test reports remain comparable; it does not infer or change
the display refresh policy.

## Configuration

| Parameter | Default | Purpose |
|---|---|---|
| `enabled` | `false` | Starts collection and displays the panel |
| `alignment` | `Alignment.topRight` | Positions the panel |
| `refreshInterval` | 500 ms | Controls panel update frequency |
| `frameBudget` | 16.667 ms | Defines the jank threshold |
| `maxSamples` | 120 | Defines the rolling timing window |
| `label` | none | Adds scenario context |
| `onUpdate` | none | Receives each displayed snapshot |

Use `onUpdate` to feed an application-owned logger or test harness:

```dart
VitreumPerformanceOverlay(
  enabled: profiling,
  onUpdate: (snapshot) {
    debugPrint(
      'fps=${snapshot.framesPerSecond.toStringAsFixed(1)} '
      'jank=${snapshot.jankPercentage.toStringAsFixed(1)}%',
    );
  },
  child: const CatalogPage(),
)
```

Avoid expensive work inside `onUpdate`; it runs on the UI isolate.

## Recommended test procedure

1. Use a physical low- or mid-range device representative of the audience.
2. Run a profile build with the overlay enabled.
3. Record OS, Flutter version, renderer, screen, quality, surface count, and
   frame budget.
4. Exercise the same scroll or animation sequence several times.
5. Compare average and maximum build/raster values and jank percentage.
6. Repeat with `VitreumQuality.low`, `balanced`, and the intended production
   quality.
7. Use DevTools or Instruments when the overlay identifies a regression.
8. Repeat without the overlay for the final trace because diagnostics have a
   small cost of their own.

Test iOS and Android separately. Different GPUs, platform views, refresh rates,
thermal states, and Flutter renderers mean results are not interchangeable.

## Interpreting bottlenecks

- High build time usually points to widget rebuilding, layout, Dart work, or
  an expensive `onUpdate`.
- High raster time usually points to large blur regions, overlapping glass,
  clipping, shadows, shader work, or animated/video backdrops.
- Increasing raster cache with stable timing is not automatically a problem;
  compare it with total memory in platform tooling.
- Jank on the first interaction can include shader or asset warm-up. Repeat the
  sequence and investigate both cold and warm behavior.

For Vitreum screens, first reduce surface size and overlap, keep glass outside
long scrolling rows, use `VitreumQuality.low` on dense routes, and avoid
continuously animating blur radius.

## Limitations

- The overlay measures Flutter engine frames, not UIKit-only rendering.
- It does not report total memory, CPU percentage, GPU utilization, energy, or
  temperature.
- Multiple Flutter engines each have their own overlay and timing stream.
- Simulator and emulator results are useful for regressions, not release
  performance claims.
- The panel and its periodic refresh introduce a small measurement effect.
- A live overlay complements rather than replaces Flutter DevTools, Android
  Studio profiling, and Xcode Instruments.

## Related documentation

- [Native iOS tab-bar integration](native_tab_scaffold.md)
- [Interaction and motion](behavior.md)
- [Visual validation](visual_validation.md)
