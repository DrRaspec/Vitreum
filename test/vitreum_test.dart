import 'dart:ui' show FrameTiming;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vitreum/src/core/vitreum_backend_selector.dart';
import 'package:vitreum/src/debug/vitreum_performance_overlay.dart';
import 'package:vitreum/vitreum.dart';

const VitreumCapabilities _androidCapabilities = VitreumCapabilities(
  platform: VitreumPlatform.android,
  nativeApiExists: false,
  nativeViewCanBeCreated: false,
  nativeBackdropCompositionValidated: false,
  nativeSingleOverlayCompositionValidated: false,
  nativeInteractiveEffectAvailable: false,
  simulatedRendererAvailable: true,
  shaderAvailable: false,
  reducedTransparency: false,
  selectedAutomaticBackend: VitreumBackend.flutterBalanced,
);

void main() {
  group('configuration', () {
    test('performance timings calculate FPS, costs, jank, and cache', () {
      final snapshot = debugSummarizePerformanceTimings(<FrameTiming>[
        FrameTiming(
          vsyncStart: 0,
          buildStart: 1000,
          buildFinish: 5000,
          rasterStart: 5000,
          rasterFinish: 11000,
          rasterFinishWallTime: 11000,
        ),
        FrameTiming(
          vsyncStart: 16667,
          buildStart: 18000,
          buildFinish: 38000,
          rasterStart: 38000,
          rasterFinish: 43000,
          rasterFinishWallTime: 43000,
          layerCacheBytes: 1024 * 1024,
          pictureCacheBytes: 512 * 1024,
        ),
      ]);

      expect(snapshot.framesPerSecond, closeTo(60, 0.01));
      expect(snapshot.averageBuildTime, const Duration(milliseconds: 12));
      expect(snapshot.averageRasterTime, const Duration(microseconds: 5500));
      expect(snapshot.maximumBuildTime, const Duration(milliseconds: 20));
      expect(snapshot.jankyFrameCount, 1);
      expect(snapshot.jankPercentage, 50);
      expect(snapshot.rasterCacheMegabytes, 1.5);
    });

    test('fallback values are clamped and non-finite values are replaced', () {
      const input = VitreumFallbackStyle(
        blurSigma: double.infinity,
        surfaceOpacity: 2,
        refractionStrength: -1,
      );
      final value = input.validated();

      expect(value.blurSigma, 14);
      expect(value.surfaceOpacity, 1);
      expect(value.refractionStrength, 0);
    });

    test('shape serializes to channel-safe values', () {
      expect(
        const VitreumShape.roundedRectangle(radius: 18).toMap(),
        <String, Object>{'kind': 'roundedRectangle', 'radius': 18.0},
      );
      expect(const VitreumShape.capsule().toMap()['kind'], 'capsule');
    });

    test('capabilities parse defensively', () {
      final value = VitreumCapabilities.fromMap(<Object?, Object?>{
        'platform': 'ios',
        'nativeApiExists': true,
        'nativeViewCanBeCreated': true,
        'selectedAutomaticBackend': 'nativeIOS',
      }, fallbackPlatform: VitreumPlatform.other);

      expect(value.platform, VitreumPlatform.ios);
      expect(value.nativeApiExists, isTrue);
      expect(value.nativeViewCanBeCreated, isTrue);
      expect(value.nativeBackdropCompositionValidated, isFalse);
      expect(value.selectedAutomaticBackend, VitreumBackend.nativeIOS);
    });
  });

  group('backend selection', () {
    test('Android automatic uses balanced Flutter renderer', () {
      expect(
        debugSelectVitreumBackend(
          mode: VitreumMode.automatic,
          quality: VitreumQuality.adaptive,
          capabilities: _androidCapabilities,
        ),
        VitreumBackend.flutterBalanced,
      );
    });

    test('high quality selects the shader path only when supported', () {
      expect(
        debugSelectVitreumBackend(
          mode: VitreumMode.simulated,
          quality: VitreumQuality.high,
          capabilities: _androidCapabilities.copyWith(shaderAvailable: true),
        ),
        VitreumBackend.flutterHigh,
      );
      expect(
        debugSelectVitreumBackend(
          mode: VitreumMode.simulated,
          quality: VitreumQuality.high,
          capabilities: _androidCapabilities,
        ),
        VitreumBackend.flutterBalanced,
      );
    });

    test('automatic and explicit native both require validation', () {
      final unvalidated = _androidCapabilities.copyWith(
        platform: VitreumPlatform.ios,
        nativeApiExists: true,
        nativeViewCanBeCreated: true,
        nativeInteractiveEffectAvailable: true,
      );
      expect(
        debugSelectVitreumBackend(
          mode: VitreumMode.automatic,
          quality: VitreumQuality.high,
          capabilities: unvalidated,
        ),
        VitreumBackend.flutterBalanced,
      );
      expect(
        debugSelectVitreumBackend(
          mode: VitreumMode.native,
          quality: VitreumQuality.high,
          capabilities: unvalidated,
        ),
        VitreumBackend.flutterBalanced,
      );
      expect(
        debugSelectVitreumBackend(
          mode: VitreumMode.native,
          quality: VitreumQuality.high,
          capabilities: unvalidated.copyWith(
            nativeBackdropCompositionValidated: true,
          ),
        ),
        VitreumBackend.nativeIOS,
      );
    });

    test('reduced transparency always selects solid', () {
      expect(
        debugSelectVitreumBackend(
          mode: VitreumMode.simulated,
          quality: VitreumQuality.high,
          capabilities: _androidCapabilities,
          reduceTransparency: true,
        ),
        VitreumBackend.solid,
      );
    });

    test('unsupported platform receives solid fallback', () {
      expect(
        debugSelectVitreumBackend(
          mode: VitreumMode.automatic,
          quality: VitreumQuality.adaptive,
          capabilities: _androidCapabilities.copyWith(
            platform: VitreumPlatform.other,
            simulatedRendererAvailable: false,
          ),
        ),
        VitreumBackend.solid,
      );
    });
  });

  group('widgets', () {
    testWidgets('performance overlay is opt-in and preserves its child', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: VitreumPerformanceOverlay(child: Text('Measured screen')),
        ),
      );

      expect(find.text('Measured screen'), findsOneWidget);
      expect(find.textContaining('VITREUM PERF'), findsNothing);

      await tester.pumpWidget(
        const MaterialApp(
          home: VitreumPerformanceOverlay(
            enabled: true,
            label: 'simulated · low',
            child: Text('Measured screen'),
          ),
        ),
      );

      expect(find.text('Measured screen'), findsOneWidget);
      expect(find.textContaining('VITREUM PERF'), findsOneWidget);
      expect(find.text('simulated · low'), findsOneWidget);
      expect(find.text('Collecting frames…'), findsOneWidget);
    });

    testWidgets('lays out its child and preserves interaction', (tester) async {
      var taps = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: Center(
            child: SizedBox(
              width: 180,
              height: 80,
              child: VitreumGlass(
                mode: VitreumMode.solid,
                shape: const VitreumShape.roundedRectangle(radius: 20),
                child: TextButton(
                  onPressed: () => taps++,
                  child: const Text('Tap'),
                ),
              ),
            ),
          ),
        ),
      );

      expect(tester.getSize(find.byType(VitreumGlass)), const Size(180, 80));
      await tester.tap(find.text('Tap'));
      expect(taps, 1);
    });

    testWidgets('button enforces an accessible minimum target', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Center(
            child: VitreumGlassButton(
              onPressed: () {},
              padding: EdgeInsets.zero,
              child: const SizedBox.shrink(),
            ),
          ),
        ),
      );
      expect(
        tester.getSize(find.byType(VitreumGlassButton)).shortestSide,
        greaterThanOrEqualTo(48),
      );
    });

    testWidgets('navigation keeps stable icons and 44 point touch targets', (
      tester,
    ) async {
      var selectedIndex = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: Center(
            child: SizedBox(
              width: 360,
              child: VitreumGlassNavigationBar(
                selectedIndex: selectedIndex,
                onDestinationSelected: (value) => selectedIndex = value,
                destinations: const <VitreumNavigationDestination>[
                  VitreumNavigationDestination(
                    icon: Icons.home_outlined,
                    label: 'Showcase',
                  ),
                  VitreumNavigationDestination(
                    icon: Icons.speed_outlined,
                    label: 'Diagnostics',
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      for (var index = 0; index < 2; index++) {
        final target = find.byKey(
          ValueKey<String>('vitreum-navigation-destination-$index'),
        );
        expect(tester.getSize(target).height, greaterThanOrEqualTo(44));
      }
      final icons = tester.widgetList<Icon>(
        find.descendant(
          of: find.byType(VitreumGlassNavigationBar),
          matching: find.byType(Icon),
        ),
      );
      expect(icons.map((icon) => icon.size), everyElement(24));

      await tester.tap(find.text('Diagnostics'));
      expect(selectedIndex, 1);
    });

    testWidgets('group installs a BackdropGroup', (tester) async {
      await tester.pumpWidget(
        const Directionality(
          textDirection: TextDirection.ltr,
          child: VitreumGlassGroup(child: SizedBox()),
        ),
      );
      expect(find.byType(BackdropGroup), findsOneWidget);
    });

    testWidgets('button press is immediate and reduced motion removes flex', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(disableAnimations: true),
            child: Center(
              child: VitreumGlassButton(
                onPressed: () {},
                child: const Text('Press'),
              ),
            ),
          ),
        ),
      );

      final gesture = await tester.startGesture(
        tester.getCenter(find.text('Press')),
      );
      await tester.pump();
      expect(tester.widget<AnimatedScale>(find.byType(AnimatedScale)).scale, 1);
      await gesture.up();
    });

    testWidgets('materialize transition is offstage when hidden', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: VitreumGlassTransition(
            visible: false,
            child: Text('Hidden glass'),
          ),
        ),
      );

      expect(
        tester
            .widgetList<Offstage>(find.byType(Offstage))
            .any((widget) => widget.offstage),
        isTrue,
      );
      expect(find.byType(IgnorePointer), findsWidgets);
    });

    testWidgets('bar minimizes down and restores up with hysteresis', (
      tester,
    ) async {
      final controller = ScrollController();
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        MaterialApp(
          home: Stack(
            children: <Widget>[
              ListView.builder(
                controller: controller,
                itemCount: 30,
                itemBuilder: (_, index) =>
                    SizedBox(height: 80, child: Text('$index')),
              ),
              VitreumGlassBar(
                scrollController: controller,
                minimizeOnScroll: true,
                child: const Text('Navigation'),
              ),
            ],
          ),
        ),
      );

      controller.jumpTo(40);
      await tester.pump();
      expect(
        tester.widget<AnimatedScale>(find.byType(AnimatedScale)).scale,
        0.86,
      );

      controller.jumpTo(10);
      await tester.pump();
      expect(tester.widget<AnimatedScale>(find.byType(AnimatedScale)).scale, 1);
    });
  });
}
