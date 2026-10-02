/// Adaptive native and simulated glass surfaces for Flutter.
library;

export 'src/core/vitreum_backend.dart'
    show VitreumBackend, VitreumMode, VitreumPlatform;
export 'src/core/vitreum_capabilities.dart' show VitreumCapabilities;
export 'src/core/vitreum_config.dart'
    show Vitreum, VitreumDebugOptions, VitreumFallbackStyle;
export 'src/core/vitreum_interaction_style.dart' show VitreumInteractionStyle;
export 'src/core/vitreum_navigation_bar_style.dart'
    show VitreumNavigationBarStyle;
export 'src/core/vitreum_quality.dart' show VitreumQuality;
export 'src/core/vitreum_shape.dart' show VitreumShape, VitreumShapeKind;
export 'src/core/vitreum_style.dart' show VitreumStyle;
export 'src/core/vitreum_theme.dart' show VitreumTheme, VitreumThemeData;
export 'src/core/vitreum_transition.dart' show VitreumTransitionType;
export 'src/debug/vitreum_performance_overlay.dart'
    show VitreumPerformanceOverlay, VitreumPerformanceSnapshot;
export 'src/widgets/vitreum_glass.dart' show VitreumGlass;
export 'src/widgets/vitreum_glass_bar.dart' show VitreumGlassBar;
export 'src/widgets/vitreum_glass_button.dart' show VitreumGlassButton;
export 'src/widgets/vitreum_glass_group.dart' show VitreumGlassGroup;
export 'src/widgets/vitreum_glass_navigation_bar.dart'
    show
        VitreumGlassNavigationBar,
        VitreumNativeGlassNavigationBar,
        VitreumNavigationDestination;
export 'src/widgets/vitreum_glass_transition.dart' show VitreumGlassTransition;
export 'src/widgets/vitreum_native_glass_overlay.dart'
    show VitreumNativeGlassOverlay;
