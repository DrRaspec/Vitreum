import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:vitreum/vitreum.dart';

const _showPerformanceOverlay = bool.fromEnvironment(
  'VITREUM_PERFORMANCE_OVERLAY',
);

void main() => runApp(const VitreumExample());

abstract final class _NativeTabReference {
  static const _channel = MethodChannel('dev.vitreum/native_tab_scaffold');

  static Future<void> present({
    required String content,
    required String minimizeBehavior,
    bool automate = false,
  }) => _channel.invokeMethod<void>('present', <String, Object>{
    'content': content,
    'minimizeBehavior': minimizeBehavior,
    'automate': automate,
  });
}

@pragma('vm:entry-point')
void vitreumShowcaseTabMain() =>
    runApp(const _NativeHostedTabApp(page: _HostedTabPage.showcase));

@pragma('vm:entry-point')
void vitreumDiagnosticsTabMain() =>
    runApp(const _NativeHostedTabApp(page: _HostedTabPage.diagnostics));

enum _HostedTabPage { showcase, diagnostics }

class _NativeHostedTabApp extends StatelessWidget {
  const _NativeHostedTabApp({required this.page});

  final _HostedTabPage page;

  @override
  Widget build(BuildContext context) => CupertinoApp(
    debugShowCheckedModeBanner: false,
    builder: (context, child) => VitreumPerformanceOverlay(
      enabled: _showPerformanceOverlay,
      label: 'Native host · ${page.name}',
      child: child ?? const SizedBox.shrink(),
    ),
    theme: const CupertinoThemeData(
      brightness: Brightness.dark,
      primaryColor: CupertinoColors.systemBlue,
      scaffoldBackgroundColor: Color(0xFF050814),
    ),
    home: _NativeHostedTabPage(page: page),
  );
}

class _NativeHostedTabPage extends StatelessWidget {
  const _NativeHostedTabPage({required this.page});

  final _HostedTabPage page;

  @override
  Widget build(BuildContext context) {
    final diagnostics = page == _HostedTabPage.diagnostics;
    final colors = diagnostics
        ? const <Color>[
            Color(0xFF161B2D),
            Color(0xFF3156D8),
            Color(0xFF0D8075),
            Color(0xFFD85A44),
          ]
        : const <Color>[
            Color(0xFFD85A44),
            Color(0xFF3156D8),
            Color(0xFF0D8075),
            Color(0xFF11182A),
          ];
    return CupertinoPageScaffold(
      child: CustomScrollView(
        slivers: <Widget>[
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 120),
            sliver: SliverList.separated(
              itemCount: 12,
              separatorBuilder: (_, _) => const SizedBox(height: 14),
              itemBuilder: (context, index) => Container(
                height: 176,
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  color: colors[index % colors.length],
                  borderRadius: BorderRadius.circular(28),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Icon(
                      diagnostics
                          ? CupertinoIcons.gauge
                          : CupertinoIcons.sparkles,
                      size: 26,
                    ),
                    const Spacer(),
                    Text(
                      diagnostics
                          ? 'Diagnostic sample ${index + 1}'
                          : 'Showcase space ${index + 1}',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Flutter content hosted by UITabBarController',
                      style: TextStyle(color: CupertinoColors.systemGrey2),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class VitreumExample extends StatelessWidget {
  const VitreumExample({super.key});

  @override
  Widget build(BuildContext context) {
    const scene = String.fromEnvironment('VITREUM_DIAGNOSTIC_SCENE');
    const tabReference = String.fromEnvironment('VITREUM_TAB_REFERENCE');
    const automateTabReference = bool.fromEnvironment('VITREUM_TAB_AUTOMATION');
    final home = switch (scene) {
      'pure' => const PureNativeDiagnosticPage(),
      'native_flutter' => const NativeOverFlutterDiagnosticPage(),
      'simulated' => const SimulatedDiagnosticPage(),
      _ when tabReference == 'simulated' => const SimulatedTabBarReferencePage(
        automate: automateTabReference,
      ),
      _ => const ExampleHome(),
    };
    return CupertinoApp(
      debugShowCheckedModeBanner: false,
      title: 'Vitreum',
      builder: (context, child) => VitreumPerformanceOverlay(
        enabled: _showPerformanceOverlay,
        label: 'Example · rolling 120 frames',
        child: child ?? const SizedBox.shrink(),
      ),
      theme: const CupertinoThemeData(
        brightness: Brightness.dark,
        primaryColor: CupertinoColors.systemCyan,
        scaffoldBackgroundColor: Color(0xFF050814),
      ),
      home: home,
    );
  }
}

class ExampleHome extends StatefulWidget {
  const ExampleHome({super.key});

  @override
  State<ExampleHome> createState() => _ExampleHomeState();
}

class _ExampleHomeState extends State<ExampleHome> {
  static const _initialTab = String.fromEnvironment('VITREUM_INITIAL_TAB');
  static const _tabReference = String.fromEnvironment('VITREUM_TAB_REFERENCE');
  static const _tabMinimizeBehavior = String.fromEnvironment(
    'VITREUM_TAB_MINIMIZE',
    defaultValue: 'onScrollDown',
  );
  static const _automateTabReference = bool.fromEnvironment(
    'VITREUM_TAB_AUTOMATION',
  );
  static const _showNavigationBounds = bool.fromEnvironment(
    'VITREUM_SHOW_NAV_BOUNDS',
  );

  late int _selectedIndex = _initialTab == 'diagnostics' ? 1 : 0;

  @override
  void initState() {
    super.initState();
    if (_tabReference.isNotEmpty &&
        defaultTargetPlatform == TargetPlatform.iOS &&
        !kIsWeb) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _NativeTabReference.present(
          content: _tabReference,
          minimizeBehavior: _tabMinimizeBehavior,
          automate: _automateTabReference,
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomSafeArea = MediaQuery.paddingOf(context).bottom;
    final topSafeArea = MediaQuery.paddingOf(context).top;
    return CupertinoPageScaffold(
      child: Stack(
        children: <Widget>[
          Positioned.fill(
            child: IndexedStack(
              index: _selectedIndex,
              children: const <Widget>[ShowcasePage(), DiagnosticsPage()],
            ),
          ),
          Positioned(
            left: 20,
            right: 20,
            bottom: bottomSafeArea + 8,
            child: VitreumGlassNavigationBar(
              selectedIndex: _selectedIndex,
              onDestinationSelected: (index) =>
                  setState(() => _selectedIndex = index),
              showDebugBounds: _showNavigationBounds,
              fallbackStyle: const VitreumFallbackStyle(
                surfaceOpacity: 0.08,
                borderOpacity: 0.18,
                shadowStrength: 0.10,
              ),
              destinations: const <VitreumNavigationDestination>[
                VitreumNavigationDestination(
                  icon: CupertinoIcons.sparkles,
                  label: 'Showcase',
                ),
                VitreumNavigationDestination(
                  icon: CupertinoIcons.gauge,
                  label: 'Diagnostics',
                ),
              ],
            ),
          ),
          Positioned(
            left: 12,
            top: topSafeArea + 4,
            child: const IgnorePointer(
              child: _ModeLabel(text: 'VITREUM SIMULATED'),
            ),
          ),
        ],
      ),
    );
  }
}

class _ModeLabel extends StatelessWidget {
  const _ModeLabel({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: CupertinoColors.black.withValues(alpha: 0.72),
      borderRadius: BorderRadius.circular(7),
    ),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Text(
        text,
        style: const TextStyle(
          color: CupertinoColors.white,
          fontSize: 9,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.4,
        ),
      ),
    ),
  );
}

class ShowcasePage extends StatefulWidget {
  const ShowcasePage({super.key});

  @override
  State<ShowcasePage> createState() => _ShowcasePageState();
}

class _ShowcasePageState extends State<ShowcasePage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _motion;
  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    final initialOffset =
        double.tryParse(
          const String.fromEnvironment(
            'VITREUM_SHOWCASE_SCROLL_OFFSET',
            defaultValue: '0',
          ),
        ) ??
        0;
    _scrollController = ScrollController(initialScrollOffset: initialOffset);
    _motion = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();
  }

  @override
  void dispose() {
    _motion.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomSafeArea = MediaQuery.paddingOf(context).bottom;
    final bottomContentPadding = 64 + bottomSafeArea + 24;
    return CupertinoPageScaffold(
      child: Stack(
        children: <Widget>[
          Positioned.fill(child: _EditorialBackground(animation: _motion)),
          SafeArea(
            bottom: false,
            child: CustomScrollView(
              controller: _scrollController,
              slivers: <Widget>[
                const SliverPadding(
                  padding: EdgeInsets.fromLTRB(22, 100, 22, 16),
                  sliver: SliverToBoxAdapter(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          'Today',
                          style: TextStyle(
                            fontSize: 34,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -1,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Your spaces, quietly organised.',
                          style: TextStyle(
                            color: CupertinoColors.systemGrey2,
                            fontSize: 17,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SliverPadding(
                  padding: EdgeInsets.fromLTRB(
                    22,
                    18,
                    22,
                    bottomContentPadding,
                  ),
                  sliver: SliverList.list(
                    children: <Widget>[
                      _contentCard(
                        'Coastal studio',
                        'Warm light · 24°',
                        CupertinoIcons.sun_max_fill,
                        const Color(0xFFDA5A44),
                      ),
                      const SizedBox(height: 16),
                      _contentCard(
                        'Evening focus',
                        'Three scenes ready',
                        CupertinoIcons.moon_stars_fill,
                        const Color(0xFF344BC2),
                      ),
                      const SizedBox(height: 16),
                      _contentCard(
                        'Listening room',
                        'Now playing · Still Corners',
                        CupertinoIcons.music_note_2,
                        const Color(0xFF137F77),
                      ),
                      const SizedBox(height: 16),
                      _contentCard(
                        'Sunset arrival',
                        'Hallway lights · 38%',
                        CupertinoIcons.sunset_fill,
                        const Color(0xFFDA5A44),
                      ),
                      const SizedBox(height: 16),
                      _contentCard(
                        'Deep work',
                        'Focus scene · 42 minutes',
                        CupertinoIcons.timer,
                        const Color(0xFF344BC2),
                      ),
                      const SizedBox(height: 28),
                      const Text(
                        'Controls float above content; ordinary content stays '
                        'in the content layer.',
                        style: TextStyle(
                          color: CupertinoColors.systemGrey2,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            left: 20,
            right: 20,
            top: MediaQuery.paddingOf(context).top + 12,
            child: VitreumGlass(
              mode: VitreumMode.simulated,
              semanticLabel: 'Search spaces',
              shape: const VitreumShape.capsule(),
              style: VitreumStyle.clear,
              fallbackStyle: const VitreumFallbackStyle(
                surfaceOpacity: 0.07,
                borderOpacity: 0.14,
                shadowStrength: 0.06,
              ),
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 15),
                child: Row(
                  children: <Widget>[
                    Icon(
                      CupertinoIcons.search,
                      size: 23,
                      color: CupertinoColors.systemGrey2,
                    ),
                    SizedBox(width: 11),
                    Text(
                      'Search spaces',
                      style: TextStyle(
                        color: CupertinoColors.systemGrey2,
                        fontSize: 16,
                      ),
                    ),
                    Spacer(),
                    Icon(
                      CupertinoIcons.mic_fill,
                      size: 22,
                      color: CupertinoColors.systemGrey2,
                    ),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            right: 24,
            bottom: bottomSafeArea + 96,
            child: SizedBox.square(
              dimension: 50,
              child: VitreumGlassButton(
                mode: VitreumMode.simulated,
                semanticLabel: 'Add space',
                onPressed: () {},
                padding: EdgeInsets.zero,
                fallbackStyle: const VitreumFallbackStyle(
                  surfaceOpacity: 0.08,
                  borderOpacity: 0.18,
                  shadowStrength: 0.10,
                ),
                child: const Icon(CupertinoIcons.add, size: 24),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _contentCard(
    String title,
    String subtitle,
    IconData icon,
    Color color,
  ) => Container(
    height: 180,
    padding: const EdgeInsets.all(22),
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(30),
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: <Color>[
          color,
          Color.lerp(color, const Color(0xFF090B14), 0.5)!,
        ],
      ),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Icon(icon, size: 28),
        const Spacer(),
        Text(
          title,
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: const TextStyle(
            color: CupertinoColors.systemGrey2,
            fontSize: 15,
          ),
        ),
      ],
    ),
  );
}

class DiagnosticsPage extends StatefulWidget {
  const DiagnosticsPage({super.key});

  @override
  State<DiagnosticsPage> createState() => _DiagnosticsPageState();
}

class _DiagnosticsPageState extends State<DiagnosticsPage> {
  VitreumCapabilities? _capabilities;
  double _stressCount = 8;
  bool _highQuality = false;
  String _minimizeBehavior = 'onScrollDown';

  @override
  void initState() {
    super.initState();
    Vitreum.getCapabilities().then((value) {
      if (mounted) setState(() => _capabilities = value);
    });
  }

  @override
  Widget build(BuildContext context) {
    final capabilities = _capabilities;
    final bottomContentPadding = 64 + MediaQuery.paddingOf(context).bottom + 24;
    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(middle: Text('Diagnostics')),
      child: SafeArea(
        child: ListView(
          padding: EdgeInsets.fromLTRB(16, 18, 16, bottomContentPadding),
          children: <Widget>[
            CupertinoListSection.insetGrouped(
              header: const Text('COMPOSITION'),
              children: <Widget>[
                _valueRow(
                  'Native API',
                  capabilities?.nativeApiExists == true
                      ? 'available'
                      : 'unavailable',
                ),
                _valueRow(
                  'Native view',
                  capabilities?.nativeViewCanBeCreated == true
                      ? 'created'
                      : 'unavailable',
                ),
                _valueRow(
                  'Interactive effect',
                  capabilities?.nativeInteractiveEffectAvailable == true
                      ? 'available'
                      : 'unavailable',
                ),
                _valueRow(
                  'Flutter backdrop composition',
                  capabilities?.nativeBackdropCompositionValidated == true
                      ? 'validated'
                      : 'failed',
                  destructive:
                      capabilities?.nativeBackdropCompositionValidated != true,
                ),
                _valueRow(
                  'Single native overlay',
                  capabilities?.nativeSingleOverlayCompositionValidated == true
                      ? 'validated'
                      : 'unavailable',
                ),
                _valueRow(
                  'Selected backend',
                  capabilities?.selectedAutomaticBackend.name ?? 'loading',
                ),
              ],
            ),
            CupertinoListSection.insetGrouped(
              header: const Text('SCENES'),
              children: <Widget>[
                _sceneButton(
                  context,
                  'Pure native UIKit',
                  const PureNativeDiagnosticPage(),
                ),
                _sceneButton(
                  context,
                  'Native glass over Flutter',
                  const NativeOverFlutterDiagnosticPage(),
                ),
                _sceneButton(
                  context,
                  'Flutter simulated',
                  const SimulatedDiagnosticPage(),
                ),
              ],
            ),
            CupertinoListSection.insetGrouped(
              header: const Text('TAB BAR COMPARISON'),
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
                  child: CupertinoSlidingSegmentedControl<String>(
                    groupValue: _minimizeBehavior,
                    children: const <String, Widget>{
                      'automatic': Text('Auto', style: TextStyle(fontSize: 12)),
                      'never': Text('Never', style: TextStyle(fontSize: 12)),
                      'onScrollDown': Text(
                        'Down',
                        style: TextStyle(fontSize: 12),
                      ),
                      'onScrollUp': Text('Up', style: TextStyle(fontSize: 12)),
                    },
                    onValueChanged: (value) {
                      if (value != null) {
                        setState(() => _minimizeBehavior = value);
                      }
                    },
                  ),
                ),
                _nativeTabButton('System native tab bar', content: 'native'),
                _nativeTabButton(
                  'Native tab bar with Flutter content',
                  content: 'flutter',
                ),
                _sceneButton(
                  context,
                  'Vitreum simulated tab bar',
                  const SimulatedTabBarReferencePage(),
                ),
              ],
            ),
            CupertinoListSection.insetGrouped(
              header: const Text('STRESS TEST'),
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text('${_stressCount.round()} surfaces'),
                      CupertinoSlider(
                        value: _stressCount,
                        min: 1,
                        max: 24,
                        divisions: 23,
                        onChanged: (value) =>
                            setState(() => _stressCount = value),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: <Widget>[
                      const Expanded(child: Text('High quality')),
                      CupertinoSwitch(
                        value: _highQuality,
                        onChanged: (value) =>
                            setState(() => _highQuality = value),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(14),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: List<Widget>.generate(
                      _stressCount.round(),
                      (index) => SizedBox(
                        width: 54,
                        height: 38,
                        child: VitreumGlass(
                          mode: VitreumMode.simulated,
                          quality: _highQuality
                              ? VitreumQuality.high
                              : VitreumQuality.low,
                          shape: const VitreumShape.capsule(),
                          child: Center(child: Text('$index')),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _valueRow(String label, String value, {bool destructive = false}) =>
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        child: Row(
          children: <Widget>[
            Expanded(child: Text(label)),
            Text(
              value,
              style: TextStyle(
                color: destructive
                    ? CupertinoColors.systemRed
                    : CupertinoColors.systemGrey,
              ),
            ),
          ],
        ),
      );

  Widget _sceneButton(BuildContext context, String label, Widget page) =>
      CupertinoButton(
        alignment: Alignment.centerLeft,
        onPressed: () => Navigator.of(
          context,
        ).push(CupertinoPageRoute<void>(builder: (_) => page)),
        child: Row(
          children: <Widget>[
            Expanded(child: Text(label)),
            const Icon(CupertinoIcons.chevron_forward, size: 18),
          ],
        ),
      );

  Widget _nativeTabButton(String label, {required String content}) =>
      CupertinoButton(
        alignment: Alignment.centerLeft,
        onPressed: defaultTargetPlatform == TargetPlatform.iOS && !kIsWeb
            ? () => _presentNativeTabs(content)
            : null,
        child: Row(
          children: <Widget>[
            Expanded(child: Text(label)),
            const Icon(CupertinoIcons.arrow_up_right_square, size: 18),
          ],
        ),
      );

  Future<void> _presentNativeTabs(String content) async {
    try {
      await _NativeTabReference.present(
        content: content,
        minimizeBehavior: _minimizeBehavior,
      );
    } on PlatformException catch (error) {
      if (!mounted) return;
      await showCupertinoDialog<void>(
        context: context,
        builder: (context) => CupertinoAlertDialog(
          title: const Text('Native host unavailable'),
          content: Text(error.message ?? error.code),
          actions: <Widget>[
            CupertinoDialogAction(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  }
}

class SimulatedTabBarReferencePage extends StatefulWidget {
  const SimulatedTabBarReferencePage({this.automate = false, super.key});

  final bool automate;

  @override
  State<SimulatedTabBarReferencePage> createState() =>
      _SimulatedTabBarReferencePageState();
}

class _SimulatedTabBarReferencePageState
    extends State<SimulatedTabBarReferencePage> {
  late final ScrollController _scrollController;
  final List<Timer> _automationTimers = <Timer>[];
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    if (widget.automate) {
      _automationTimers.add(
        Timer.periodic(const Duration(seconds: 1), (timer) {
          switch (timer.tick % 10) {
            case 3:
              if (mounted) setState(() => _selectedIndex = 1);
            case 4:
              if (mounted) setState(() => _selectedIndex = 0);
            case 5:
              if (_scrollController.hasClients) {
                _scrollController.animateTo(
                  940,
                  duration: const Duration(milliseconds: 900),
                  curve: Curves.easeInOutCubic,
                );
              }
            case 7:
              if (_scrollController.hasClients) {
                _scrollController.animateTo(
                  0,
                  duration: const Duration(milliseconds: 900),
                  curve: Curves.easeInOutCubic,
                );
              }
          }
        }),
      );
    }
  }

  @override
  void dispose() {
    for (final timer in _automationTimers) {
      timer.cancel();
    }
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mediaPadding = MediaQuery.paddingOf(context);
    final diagnostics = _selectedIndex == 1;
    final colors = diagnostics
        ? const <Color>[Color(0xFF11182A), Color(0xFF3156D8), Color(0xFF0D8075)]
        : const <Color>[
            Color(0xFFD85A44),
            Color(0xFF3156D8),
            Color(0xFF0D8075),
          ];
    return CupertinoPageScaffold(
      child: Stack(
        children: <Widget>[
          Positioned.fill(
            child: ListView.separated(
              controller: _scrollController,
              padding: EdgeInsets.fromLTRB(
                20,
                mediaPadding.top + 64,
                20,
                64 + mediaPadding.bottom + 24,
              ),
              itemCount: 10,
              separatorBuilder: (_, _) => const SizedBox(height: 14),
              itemBuilder: (context, index) => Container(
                height: 180,
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  color: colors[index % colors.length],
                  borderRadius: BorderRadius.circular(28),
                ),
                alignment: Alignment.bottomLeft,
                child: Text(
                  diagnostics
                      ? 'Diagnostic sample ${index + 1}'
                      : 'Showcase sample ${index + 1}',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            left: 20,
            right: 20,
            bottom: mediaPadding.bottom + 8,
            child: VitreumGlassNavigationBar(
              selectedIndex: _selectedIndex,
              onDestinationSelected: (value) =>
                  setState(() => _selectedIndex = value),
              destinations: const <VitreumNavigationDestination>[
                VitreumNavigationDestination(
                  icon: CupertinoIcons.sparkles,
                  label: 'Showcase',
                ),
                VitreumNavigationDestination(
                  icon: CupertinoIcons.gauge,
                  label: 'Diagnostics',
                ),
              ],
            ),
          ),
          Positioned(
            left: 12,
            top: mediaPadding.top + 8,
            child: const _ModeLabel(text: 'VITREUM SIMULATED'),
          ),
        ],
      ),
    );
  }
}

class PureNativeDiagnosticPage extends StatelessWidget {
  const PureNativeDiagnosticPage({super.key});

  @override
  Widget build(BuildContext context) => CupertinoPageScaffold(
    child: _supportsUIKitViews
        ? const UiKitView(viewType: 'dev.vitreum/native_diagnostic')
        : const Center(child: Text('PURE NATIVE — iOS only')),
  );
}

class NativeOverFlutterDiagnosticPage extends StatelessWidget {
  const NativeOverFlutterDiagnosticPage({super.key});

  @override
  Widget build(BuildContext context) => CupertinoPageScaffold(
    child: _DiagnosticScene(
      label: 'NATIVE OVER FLUTTER',
      surface: _supportsUIKitViews
          ? const _RawNativeDiagnosticGlass()
          : const Center(child: Text('Native platform view unavailable')),
    ),
  );
}

class SimulatedDiagnosticPage extends StatelessWidget {
  const SimulatedDiagnosticPage({super.key});

  @override
  Widget build(BuildContext context) => const CupertinoPageScaffold(
    child: _DiagnosticScene(
      label: 'FLUTTER SIMULATED',
      surface: VitreumGlass(
        mode: VitreumMode.simulated,
        quality: VitreumQuality.high,
        style: VitreumStyle.regular,
        shape: VitreumShape.roundedRectangle(radius: 36),
        child: Center(
          child: Text(
            'FLUTTER FILTER',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
      ),
    ),
  );
}

class _RawNativeDiagnosticGlass extends StatelessWidget {
  const _RawNativeDiagnosticGlass();

  @override
  Widget build(BuildContext context) => Stack(
    fit: StackFit.expand,
    children: <Widget>[
      const UiKitView(
        viewType: 'dev.vitreum/native_glass',
        creationParams: <String, Object?>{
          'shape': <String, Object>{'kind': 'roundedRectangle', 'radius': 36.0},
          'style': 'regular',
          'interactive': false,
          'tint': null,
        },
        creationParamsCodec: StandardMessageCodec(),
      ),
      const IgnorePointer(
        child: Center(
          child: Text(
            'FLUTTER FOREGROUND',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
      ),
    ],
  );
}

class _DiagnosticScene extends StatefulWidget {
  const _DiagnosticScene({required this.label, required this.surface});

  final String label;
  final Widget surface;

  @override
  State<_DiagnosticScene> createState() => _DiagnosticSceneState();
}

class _DiagnosticSceneState extends State<_DiagnosticScene>
    with SingleTickerProviderStateMixin {
  late final AnimationController _motion;

  @override
  void initState() {
    super.initState();
    _motion = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
  }

  @override
  void dispose() {
    _motion.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Stack(
    children: <Widget>[
      Positioned.fill(child: _DiagnosticBackground(animation: _motion)),
      Center(child: SizedBox(width: 310, height: 112, child: widget.surface)),
      Positioned(
        left: 0,
        right: 0,
        top: MediaQuery.paddingOf(context).top + 18,
        child: Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
            decoration: BoxDecoration(
              color: CupertinoColors.systemRed,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              widget.label,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ),
    ],
  );
}

class _DiagnosticBackground extends StatelessWidget {
  const _DiagnosticBackground({required this.animation});

  final Animation<double> animation;

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: animation,
    builder: (context, child) => CustomPaint(
      painter: _DiagnosticPainter(animation.value),
      child: Stack(
        children: <Widget>[
          Positioned(
            left: animation.value * MediaQuery.sizeOf(context).width - 120,
            top: MediaQuery.sizeOf(context).height * 0.68,
            child: const Text(
              'MOVING FLUTTER TEXT',
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Positioned(
            left: 18,
            bottom: 28,
            child: Text(
              'FRAME ${(animation.value * 100000).round().toString().padLeft(6, '0')}',
              style: const TextStyle(
                fontFamily: 'monospace',
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

class _DiagnosticPainter extends CustomPainter {
  const _DiagnosticPainter(this.phase);

  final double phase;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment(math.sin(phase * math.pi * 2), -1),
          end: Alignment(-math.cos(phase * math.pi * 2), 1),
          colors: const <Color>[
            Color(0xFF071633),
            Color(0xFF1678E8),
            Color(0xFFDD326F),
            Color(0xFF29D1A4),
          ],
        ).createShader(rect),
    );

    const cell = 28.0;
    final checker = Paint();
    for (var y = 0.0; y < size.height; y += cell) {
      for (var x = 0.0; x < size.width; x += cell) {
        checker.color = ((x / cell + y / cell).round().isEven)
            ? const Color(0x33000000)
            : const Color(0x22FFFFFF);
        canvas.drawRect(Rect.fromLTWH(x, y, cell, cell), checker);
      }
    }

    final linePaint = Paint()
      ..color = const Color(0xCCFFFFFF)
      ..strokeWidth = 3;
    final offset = phase * 52;
    for (var x = -size.height + offset; x < size.width; x += 52) {
      canvas.drawLine(
        Offset(x, 0),
        Offset(x + size.height, size.height),
        linePaint,
      );
    }
    for (var y = 90.0; y < size.height; y += 96) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), linePaint);
    }
  }

  @override
  bool shouldRepaint(_DiagnosticPainter oldDelegate) =>
      oldDelegate.phase != phase;
}

class _EditorialBackground extends StatelessWidget {
  const _EditorialBackground({required this.animation});

  final Animation<double> animation;

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: animation,
    builder: (context, child) {
      final angle = animation.value * math.pi * 2;
      return Stack(
        fit: StackFit.expand,
        children: <Widget>[
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment(math.sin(angle) * 0.6, -1),
                end: Alignment(-math.cos(angle) * 0.4, 1),
                colors: const <Color>[
                  Color(0xFF070A14),
                  Color(0xFF101B35),
                  Color(0xFF241539),
                  Color(0xFF071B24),
                ],
              ),
            ),
          ),
          Positioned(
            top: 36 + math.sin(angle) * 20,
            right: -60 + math.cos(angle) * 24,
            child: const SizedBox.square(
              dimension: 280,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: <Color>[
                      Color(0x8A16BDE8),
                      Color(0x3D5C65E8),
                      Color(0x005C65E8),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            top: 120 + math.cos(angle) * 18,
            left: -100 + math.sin(angle) * 20,
            child: const SizedBox.square(
              dimension: 240,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: <Color>[
                      Color(0x66E53C86),
                      Color(0x205C65E8),
                      Color(0x005C65E8),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      );
    },
  );
}

bool get _supportsUIKitViews =>
    !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;
