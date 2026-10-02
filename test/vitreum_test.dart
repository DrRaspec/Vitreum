import 'dart:ui' show FrameTiming;

import 'package:flutter/cupertino.dart' show CupertinoApp;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vitreum/src/core/vitreum_backend_selector.dart';
import 'package:vitreum/src/debug/vitreum_performance_overlay.dart';
import 'package:vitreum/src/rendering/solid_glass_renderer.dart';
import 'package:vitreum/src/widgets/vitreum_scroll_minimizer.dart';
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

    test('edge and shadow values are clamped safely', () {
      const input = VitreumFallbackStyle(
        edgeWidth: -2,
        shadowBlurSigma: double.infinity,
        shadowOffset: Offset(double.infinity, -80),
      );
      final value = input.validated();

      expect(value.edgeWidth, 0);
      expect(value.shadowBlurSigma, 8);
      expect(value.shadowOffset, const Offset(0, -40));
    });

    test('interaction and navigation styles reject unsafe layout values', () {
      const interaction = VitreumInteractionStyle(
        pressedScale: double.nan,
        duration: Duration(seconds: -1),
        minimumSize: Size(double.infinity, -10),
      );
      final interactionValue = interaction.validated();
      expect(interactionValue.pressedScale, 0.975);
      expect(interactionValue.duration, const Duration(milliseconds: 120));
      expect(interactionValue.minimumSize, const Size(48, 0));

      const navigation = VitreumNavigationBarStyle(
        height: double.infinity,
        horizontalPadding: -5,
      );
      final navigationValue = navigation.validated();
      expect(navigationValue.height, 64);
      expect(navigationValue.horizontalPadding, 0);
    });

    test('nullable widget configuration fields encode theme inheritance', () {
      const surface = VitreumGlass(child: SizedBox());
      expect(surface.style, isNull);
      expect(surface.quality, isNull);
      expect(surface.fallbackStyle, isNull);

      const configured = VitreumGlass(
        style: VitreumStyle.clear,
        quality: VitreumQuality.low,
        fallbackStyle: VitreumFallbackStyle(blurSigma: 4),
        child: SizedBox(),
      );
      expect(configured.style, VitreumStyle.clear);
      expect(configured.quality, VitreumQuality.low);
      expect(configured.fallbackStyle?.blurSigma, 4);
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

    testWidgets('custom zero-blur shadow and wide edge render safely', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Center(
            child: SizedBox(
              width: 160,
              height: 56,
              child: VitreumGlass(
                mode: VitreumMode.simulated,
                shape: VitreumShape.capsule(),
                fallbackStyle: VitreumFallbackStyle(
                  edgeWidth: 8,
                  shadowBlurSigma: 0,
                ),
                child: SizedBox.expand(),
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(tester.takeException(), isNull);
    });

    testWidgets('package theme supplies omitted surface defaults', (
      tester,
    ) async {
      const tint = Color(0xFF336699);
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(
            extensions: const <ThemeExtension<dynamic>>[
              VitreumThemeData(
                style: VitreumStyle.clear,
                quality: VitreumQuality.low,
                tint: tint,
              ),
            ],
          ),
          home: const VitreumGlass(
            mode: VitreumMode.solid,
            child: SizedBox(width: 100, height: 40),
          ),
        ),
      );

      expect(
        tester.widget<SolidGlassRenderer>(find.byType(SolidGlassRenderer)).tint,
        tint,
      );
    });

    testWidgets('inherited theme and explicit values follow precedence', (
      tester,
    ) async {
      const materialTint = Color(0xFFAA0000);
      const inheritedTint = Color(0xFF00AA00);
      const explicitTint = Color(0xFF0000AA);

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(
            extensions: const <ThemeExtension<dynamic>>[
              VitreumThemeData(tint: materialTint),
            ],
          ),
          home: const VitreumTheme(
            data: VitreumThemeData(tint: inheritedTint),
            child: Column(
              children: <Widget>[
                VitreumGlass(
                  mode: VitreumMode.solid,
                  child: SizedBox(width: 100, height: 40),
                ),
                VitreumGlass(
                  mode: VitreumMode.solid,
                  tint: explicitTint,
                  child: SizedBox(width: 100, height: 40),
                ),
                VitreumGlass(
                  mode: VitreumMode.solid,
                  inheritTint: false,
                  child: SizedBox(width: 100, height: 40),
                ),
              ],
            ),
          ),
        ),
      );

      final renderers = tester.widgetList<SolidGlassRenderer>(
        find.byType(SolidGlassRenderer),
      );
      expect(renderers.map((renderer) => renderer.tint), <Color?>[
        inheritedTint,
        explicitTint,
        null,
      ]);
    });

    testWidgets('themed high quality enables button pointer tracking', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(
            extensions: const <ThemeExtension<dynamic>>[
              VitreumThemeData(quality: VitreumQuality.high),
            ],
          ),
          home: VitreumGlassButton(
            onPressed: () {},
            child: const Text('Hover'),
          ),
        ),
      );

      final mouseRegions = tester.widgetList<MouseRegion>(
        find.descendant(
          of: find.byType(VitreumGlassButton),
          matching: find.byType(MouseRegion),
        ),
      );
      expect(mouseRegions.any((region) => region.onHover != null), isTrue);
    });

    testWidgets('clip behavior controls the child but keeps glass bounded', (
      tester,
    ) async {
      Future<void> pumpSurface(Clip clipBehavior) => tester.pumpWidget(
        MaterialApp(
          home: VitreumGlass(
            mode: VitreumMode.solid,
            shape: const VitreumShape.capsule(),
            clipBehavior: clipBehavior,
            child: const SizedBox(width: 120, height: 48),
          ),
        ),
      );

      await pumpSurface(Clip.none);
      var clips = find.descendant(
        of: find.byType(VitreumGlass),
        matching: find.byType(ClipPath),
      );
      expect(clips, findsOneWidget);

      await pumpSurface(Clip.hardEdge);
      clips = find.descendant(
        of: find.byType(VitreumGlass),
        matching: find.byType(ClipPath),
      );
      expect(clips, findsNWidgets(2));
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

    testWidgets('inherited theme works without a Material theme extension', (
      tester,
    ) async {
      const tint = Color(0xFF446688);
      await tester.pumpWidget(
        const CupertinoApp(
          home: VitreumTheme(
            data: VitreumThemeData(tint: tint),
            child: VitreumGlass(
              mode: VitreumMode.solid,
              child: SizedBox(width: 100, height: 40),
            ),
          ),
        ),
      );

      expect(
        tester.widget<SolidGlassRenderer>(find.byType(SolidGlassRenderer)).tint,
        tint,
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

    testWidgets('button interaction style controls pressed scale', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Center(
            child: VitreumGlassButton(
              onPressed: () {},
              interactionStyle: const VitreumInteractionStyle(
                pressedScale: 0.9,
                duration: Duration.zero,
              ),
              child: const Text('Press'),
            ),
          ),
        ),
      );

      final gesture = await tester.startGesture(
        tester.getCenter(find.text('Press')),
      );
      await tester.pump();
      expect(
        tester.widget<AnimatedScale>(find.byType(AnimatedScale)).scale,
        0.9,
      );
      await gesture.up();
    });

    testWidgets('navigation appearance controls dimensions and colors', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Center(
            child: SizedBox(
              width: 360,
              child: VitreumGlassNavigationBar(
                selectedIndex: 0,
                onDestinationSelected: (_) {},
                navigationStyle: const VitreumNavigationBarStyle(
                  height: 72,
                  iconSize: 20,
                  selectedColor: Colors.amber,
                ),
                destinations: const <VitreumNavigationDestination>[
                  VitreumNavigationDestination(
                    icon: Icons.home_outlined,
                    label: 'Home',
                  ),
                  VitreumNavigationDestination(
                    icon: Icons.settings_outlined,
                    label: 'Settings',
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      expect(tester.getSize(find.byType(VitreumGlassNavigationBar)).height, 72);
      final firstIcon = tester.widget<Icon>(find.byType(Icon).first);
      expect(firstIcon.size, 20);
      expect(firstIcon.color, Colors.amber);
    });

    testWidgets('native navigation uses the single native overlay path', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Center(
            child: SizedBox(
              width: 360,
              child: VitreumNativeGlassNavigationBar(
                selectedIndex: 0,
                onDestinationSelected: (_) {},
                destinations: const <VitreumNavigationDestination>[
                  VitreumNavigationDestination(
                    icon: Icons.photo_library_outlined,
                    label: 'Gallery',
                  ),
                  VitreumNavigationDestination(
                    icon: Icons.insert_drive_file_outlined,
                    label: 'File',
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      expect(find.byType(VitreumNativeGlassNavigationBar), findsOneWidget);
      expect(find.byType(VitreumNativeGlassOverlay), findsOneWidget);
      expect(find.text('Gallery'), findsOneWidget);
      expect(find.text('File'), findsOneWidget);
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

    testWidgets('scroll-aware bar starts expanded', (tester) async {
      final controller = ScrollController();
      addTearDown(controller.dispose);
      await tester.pumpWidget(_barHarness(controller: controller));

      expect(_minimizerScale(tester), 1);
      expect(_minimizerSlide(tester), Offset.zero);
    });

    testWidgets('scrolling down minimizes and scrolling up expands', (
      tester,
    ) async {
      final controller = ScrollController();
      addTearDown(controller.dispose);
      await tester.pumpWidget(_barHarness(controller: controller));

      await tester.drag(find.byKey(_scrollableKey), const Offset(0, -80));
      await tester.pump();
      expect(_minimizerScale(tester), 0.9);

      await tester.drag(find.byKey(_scrollableKey), const Offset(0, 50));
      await tester.pump();
      expect(_minimizerScale(tester), 1);
    });

    testWidgets('minimized bar remains visible and keeps safe placement', (
      tester,
    ) async {
      final controller = ScrollController();
      addTearDown(controller.dispose);
      await tester.pumpWidget(_barHarness(controller: controller));

      await tester.drag(find.byKey(_scrollableKey), const Offset(0, -80));
      await tester.pump();

      expect(find.text('Navigation'), findsOneWidget);
      expect(_minimizerScale(tester), greaterThan(0));
      expect(_minimizerSlide(tester), Offset.zero);
      expect(
        tester
            .widgetList<Offstage>(find.byType(Offstage))
            .every((widget) => !widget.offstage),
        isTrue,
      );
    });

    testWidgets('tapping a minimized bar expands it and activates its child', (
      tester,
    ) async {
      final controller = ScrollController();
      addTearDown(controller.dispose);
      var taps = 0;
      await tester.pumpWidget(
        _barHarness(
          controller: controller,
          child: GestureDetector(
            onTap: () => taps++,
            child: const Text('Navigation'),
          ),
        ),
      );

      await tester.drag(find.byKey(_scrollableKey), const Offset(0, -80));
      await tester.pump();
      expect(_minimizerScale(tester), 0.9);

      await tester.tap(find.text('Navigation'));
      await tester.pump();
      expect(_minimizerScale(tester), 1);
      expect(taps, 1);
    });

    testWidgets('navigation destinations remain selectable while minimized', (
      tester,
    ) async {
      final controller = ScrollController();
      addTearDown(controller.dispose);
      var selectedIndex = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: StatefulBuilder(
            builder: (context, setState) => Stack(
              children: <Widget>[
                ListView.builder(
                  key: _scrollableKey,
                  controller: controller,
                  physics: const ClampingScrollPhysics(),
                  itemCount: 30,
                  itemBuilder: (_, index) =>
                      SizedBox(height: 80, child: Text('$index')),
                ),
                Align(
                  alignment: Alignment.bottomCenter,
                  child: SizedBox(
                    width: 360,
                    child: VitreumGlassNavigationBar(
                      scrollController: controller,
                      minimizeOnScroll: true,
                      selectedIndex: selectedIndex,
                      onDestinationSelected: (value) =>
                          setState(() => selectedIndex = value),
                      destinations: const <VitreumNavigationDestination>[
                        VitreumNavigationDestination(
                          icon: Icons.home_outlined,
                          label: 'Home',
                        ),
                        VitreumNavigationDestination(
                          icon: Icons.settings_outlined,
                          label: 'Settings',
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );

      await tester.drag(find.byKey(_scrollableKey), const Offset(0, -80));
      await tester.pump();
      expect(_minimizerScale(tester), 0.9);

      await tester.tap(find.text('Settings'));
      await tester.pumpAndSettle();
      expect(selectedIndex, 1);
      expect(_minimizerScale(tester), 1);
      expect(tester.takeException(), isNull);
    });

    testWidgets('tiny scroll movement does not toggle the bar', (tester) async {
      final controller = ScrollController();
      addTearDown(controller.dispose);
      await tester.pumpWidget(_barHarness(controller: controller));

      final gesture = await tester.startGesture(
        tester.getCenter(find.byKey(_scrollableKey)),
      );
      await gesture.moveBy(const Offset(0, -22));
      await tester.pump();
      expect(_minimizerScale(tester), 1);
      await gesture.up();
    });

    testWidgets('rapid sub-threshold direction changes do not flicker', (
      tester,
    ) async {
      final controller = ScrollController();
      addTearDown(controller.dispose);
      await tester.pumpWidget(_barHarness(controller: controller));

      for (final movement in const <Offset>[
        Offset(0, -22),
        Offset(0, 22),
        Offset(0, -22),
        Offset(0, 22),
      ]) {
        await tester.drag(find.byKey(_scrollableKey), movement);
        await tester.pump();
        expect(_minimizerScale(tester), 1);
      }
    });

    testWidgets('repeated same-direction events do not rebuild the bar', (
      tester,
    ) async {
      final controller = ScrollController();
      addTearDown(controller.dispose);
      var builds = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: Stack(
            children: <Widget>[
              ListView.builder(
                key: _scrollableKey,
                controller: controller,
                physics: const ClampingScrollPhysics(),
                itemCount: 30,
                itemBuilder: (_, index) =>
                    SizedBox(height: 80, child: Text('$index')),
              ),
              Align(
                alignment: Alignment.bottomCenter,
                child: VitreumScrollMinimizer(
                  scrollController: controller,
                  minimizeOnScroll: true,
                  trackScrollEdge: false,
                  expandOnInteraction: true,
                  minimizedTranslation: Offset.zero,
                  minimizedScale: 0.9,
                  builder: (context, hasScrolledContent) {
                    builds++;
                    return const SizedBox(
                      width: 240,
                      height: 64,
                      child: Text('Navigation'),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      );

      await tester.drag(find.byKey(_scrollableKey), const Offset(0, -80));
      await tester.pump();
      final buildsAfterMinimize = builds;
      await tester.drag(find.byKey(_scrollableKey), const Offset(0, -80));
      await tester.pump();

      expect(_minimizerScale(tester), 0.9);
      expect(builds, buildsAfterMinimize);
    });

    testWidgets('changing controllers detaches listeners exactly once', (
      tester,
    ) async {
      final first = _TrackingScrollController();
      final second = _TrackingScrollController();
      addTearDown(first.dispose);
      addTearDown(second.dispose);
      var controller = first;
      late StateSetter rebuild;
      await tester.pumpWidget(
        StatefulBuilder(
          builder: (context, setState) {
            rebuild = setState;
            return _barHarness(controller: controller);
          },
        ),
      );
      expect(first.listenerAdds, 1);

      rebuild(() => controller = second);
      await tester.pump();
      expect(first.listenerRemoves, 1);
      expect(second.listenerAdds, 1);

      await tester.pumpWidget(const SizedBox());
      expect(second.listenerRemoves, 1);
      first.emit();
      second.emit();
      expect(tester.takeException(), isNull);
    });

    testWidgets('non-scrollable content remains expanded', (tester) async {
      final controller = ScrollController();
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        _barHarness(controller: controller, itemCount: 1),
      );

      await tester.drag(find.byKey(_scrollableKey), const Offset(0, -120));
      await tester.pump();
      expect(_minimizerScale(tester), 1);
    });

    testWidgets('idle programmatic movement does not minimize the bar', (
      tester,
    ) async {
      final controller = ScrollController();
      addTearDown(controller.dispose);
      await tester.pumpWidget(_barHarness(controller: controller));

      controller.jumpTo(80);
      await tester.pump();
      expect(_minimizerScale(tester), 1);
    });

    testWidgets('reaching the initial edge restores a minimized bar', (
      tester,
    ) async {
      final controller = ScrollController();
      addTearDown(controller.dispose);
      await tester.pumpWidget(_barHarness(controller: controller));

      await tester.drag(find.byKey(_scrollableKey), const Offset(0, -80));
      await tester.pump();
      expect(_minimizerScale(tester), 0.9);

      controller.jumpTo(controller.position.minScrollExtent);
      await tester.pump();
      expect(_minimizerScale(tester), 1);
    });

    testWidgets('keyboard inset changes preserve the current bar state', (
      tester,
    ) async {
      final controller = ScrollController();
      addTearDown(controller.dispose);
      await tester.pumpWidget(_barHarness(controller: controller));

      await tester.pumpWidget(
        _barHarness(
          controller: controller,
          viewInsets: const EdgeInsets.only(bottom: 300),
        ),
      );
      expect(_minimizerScale(tester), 1);
      expect(_minimizerSlide(tester), Offset.zero);

      await tester.drag(find.byKey(_scrollableKey), const Offset(0, -80));
      await tester.pump();
      expect(_minimizerScale(tester), 0.9);

      await tester.pumpWidget(
        _barHarness(controller: controller, viewInsets: EdgeInsets.zero),
      );
      expect(_minimizerScale(tester), 0.9);
      expect(_minimizerSlide(tester), Offset.zero);
    });

    testWidgets('reverse lists normalize down and up directions', (
      tester,
    ) async {
      final controller = ScrollController();
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        _barHarness(controller: controller, reverse: true),
      );

      controller.jumpTo(100);
      await tester.pump();
      expect(_minimizerScale(tester), 1);

      await tester.drag(find.byKey(_scrollableKey), const Offset(0, -80));
      await tester.pump();
      expect(_minimizerScale(tester), 0.9);

      await tester.drag(find.byKey(_scrollableKey), const Offset(0, 50));
      await tester.pump();
      expect(_minimizerScale(tester), 1);
    });

    testWidgets(
      'disabling minimization and interaction expansion are honored',
      (tester) async {
        final disabledController = ScrollController();
        addTearDown(disabledController.dispose);
        await tester.pumpWidget(
          _barHarness(controller: disabledController, minimizeOnScroll: false),
        );
        await tester.drag(find.byKey(_scrollableKey), const Offset(0, -100));
        await tester.pump();
        expect(_minimizerScale(tester), 1);

        final interactionController = ScrollController();
        addTearDown(interactionController.dispose);
        await tester.pumpWidget(
          _barHarness(
            controller: interactionController,
            expandOnInteraction: false,
          ),
        );
        await tester.drag(find.byKey(_scrollableKey), const Offset(0, -80));
        await tester.pump();
        expect(_minimizerScale(tester), 0.9);

        await tester.tap(find.text('Navigation'));
        await tester.pump();
        expect(_minimizerScale(tester), 0.9);
      },
    );
  });
}

const _scrollableKey = ValueKey<String>('scrollable');

Widget _barHarness({
  required ScrollController controller,
  bool reverse = false,
  int itemCount = 30,
  bool minimizeOnScroll = true,
  bool expandOnInteraction = true,
  EdgeInsets viewInsets = EdgeInsets.zero,
  Widget child = const Text('Navigation'),
}) => MaterialApp(
  builder: (context, child) => MediaQuery(
    data: MediaQuery.of(context).copyWith(viewInsets: viewInsets),
    child: child!,
  ),
  home: Stack(
    children: <Widget>[
      ListView.builder(
        key: _scrollableKey,
        controller: controller,
        reverse: reverse,
        physics: const ClampingScrollPhysics(),
        itemCount: itemCount,
        itemBuilder: (_, index) => SizedBox(height: 80, child: Text('$index')),
      ),
      Align(
        alignment: Alignment.bottomCenter,
        child: VitreumGlassBar(
          scrollController: controller,
          minimizeOnScroll: minimizeOnScroll,
          expandOnInteraction: expandOnInteraction,
          child: child,
        ),
      ),
    ],
  ),
);

double _minimizerScale(WidgetTester tester) => tester
    .widget<AnimatedScale>(
      find.byKey(const ValueKey('vitreum-scroll-minimizer-scale')),
    )
    .scale;

Offset _minimizerSlide(WidgetTester tester) => tester
    .widget<AnimatedSlide>(
      find.byKey(const ValueKey('vitreum-scroll-minimizer-slide')),
    )
    .offset;

class _TrackingScrollController extends ScrollController {
  int listenerAdds = 0;
  int listenerRemoves = 0;

  @override
  void addListener(VoidCallback listener) {
    listenerAdds++;
    super.addListener(listener);
  }

  @override
  void removeListener(VoidCallback listener) {
    listenerRemoves++;
    super.removeListener(listener);
  }

  void emit() => notifyListeners();
}
