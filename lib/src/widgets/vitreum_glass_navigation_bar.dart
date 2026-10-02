import 'package:flutter/material.dart';

import '../core/vitreum_backend.dart';
import '../core/vitreum_config.dart';
import '../core/vitreum_navigation_bar_style.dart';
import '../core/vitreum_quality.dart';
import '../core/vitreum_shape.dart';
import '../core/vitreum_style.dart';
import '../core/vitreum_theme.dart';
import 'vitreum_glass.dart';
import 'vitreum_native_glass_overlay.dart';
import 'vitreum_scroll_minimizer.dart';

/// A destination displayed by [VitreumGlassNavigationBar].
@immutable
class VitreumNavigationDestination {
  const VitreumNavigationDestination({required this.icon, required this.label});

  /// Icon displayed for the destination.
  final IconData icon;

  /// Visible and semantic destination label.
  final String label;
}

/// A cross-platform Flutter approximation of floating glass navigation.
///
/// This widget is not a `UITabBar`, does not use `UITabBarController`, and
/// never claims native iOS tab-bar behavior. Use a native host integration
/// such as the example app's `VitreumNativeTabScaffold` when the real system
/// tab bar is required.
class VitreumGlassNavigationBar extends StatefulWidget {
  const VitreumGlassNavigationBar({
    required this.destinations,
    required this.selectedIndex,
    required this.onDestinationSelected,
    this.style,
    this.quality,
    this.fallbackStyle,
    this.navigationStyle,
    this.shape = const VitreumShape.capsule(),
    this.tint,
    this.inheritTint = true,
    this.scrollController,
    this.minimizeOnScroll = false,
    this.scrollEdgeTreatment = false,
    this.expandOnInteraction = true,
    this.minimizedTranslation = Offset.zero,
    this.minimizedScale = 0.9,
    this.clipBehavior = Clip.antiAlias,
    this.showDebugBounds = false,
    super.key,
  }) : assert(destinations.length >= 2),
       assert(selectedIndex >= 0 && selectedIndex < destinations.length),
       _useNativeOverlay = false;

  const VitreumGlassNavigationBar._native({
    required this.destinations,
    required this.selectedIndex,
    required this.onDestinationSelected,
    this.style,
    this.quality,
    this.fallbackStyle,
    this.navigationStyle,
    this.shape = const VitreumShape.capsule(),
    this.tint,
    this.inheritTint = true,
    this.scrollController,
    this.minimizeOnScroll = false,
    this.scrollEdgeTreatment = false,
    this.expandOnInteraction = true,
    this.minimizedTranslation = Offset.zero,
    this.minimizedScale = 0.9,
    this.clipBehavior = Clip.antiAlias,
    this.showDebugBounds = false,
    super.key,
  }) : assert(destinations.length >= 2),
       assert(selectedIndex >= 0 && selectedIndex < destinations.length),
       _useNativeOverlay = true;

  /// Destinations displayed from left to right.
  final List<VitreumNavigationDestination> destinations;

  /// Index of the currently selected destination.
  final int selectedIndex;

  /// Called with the index of an activated destination.
  final ValueChanged<int> onDestinationSelected;

  /// Material style, or null to inherit from [VitreumThemeData].
  final VitreumStyle? style;

  /// Simulation quality, or null to inherit from [VitreumThemeData].
  final VitreumQuality? quality;

  /// Fallback configuration, or null to inherit from [VitreumThemeData].
  final VitreumFallbackStyle? fallbackStyle;

  /// Layout and colors, or null to inherit from [VitreumThemeData].
  final VitreumNavigationBarStyle? navigationStyle;

  /// Navigation surface and clipping geometry.
  final VitreumShape shape;

  /// Optional tint, with theme fallback.
  final Color? tint;

  /// Whether a null [tint] inherits the theme tint.
  final bool inheritTint;

  /// Scroll source used by [minimizeOnScroll] and [scrollEdgeTreatment].
  final ScrollController? scrollController;

  /// Minimizes after sustained screen-wise downward user scrolling and
  /// restores while scrolling upward. Reversed vertical scrollables are
  /// detected from their attached scroll position.
  final bool minimizeOnScroll;

  /// Strengthens simulated separation once content has moved under the bar.
  final bool scrollEdgeTreatment;

  /// Whether pointer interaction restores a minimized bar before its
  /// destination handles the same interaction.
  final bool expandOnInteraction;

  /// Fractional translation applied in the minimized state.
  final Offset minimizedTranslation;

  /// Scale applied in the minimized state. Every destination remains visible
  /// and selectable.
  final double minimizedScale;

  final bool _useNativeOverlay;

  /// How navigation content is clipped to [shape].
  final Clip clipBehavior;

  /// Whether to draw a diagnostic rectangle around the widget bounds.
  final bool showDebugBounds;

  @override
  State<VitreumGlassNavigationBar> createState() =>
      _VitreumGlassNavigationBarState();
}

class _VitreumGlassNavigationBarState extends State<VitreumGlassNavigationBar> {
  int? _pressedIndex;

  @override
  Widget build(BuildContext context) {
    final theme = VitreumThemeData.of(context);
    final style = widget.style ?? theme.style;
    final quality = widget.quality ?? theme.quality;
    final fallbackStyle = widget.fallbackStyle ?? theme.fallbackStyle;
    final navigationStyle = widget.navigationStyle ?? theme.navigationBarStyle;
    final navigationValues = navigationStyle.validated();
    final tint = widget.tint ?? (widget.inheritTint ? theme.tint : null);
    return VitreumScrollMinimizer(
      scrollController: widget.scrollController,
      minimizeOnScroll: widget.minimizeOnScroll,
      trackScrollEdge: widget.scrollEdgeTreatment,
      expandOnInteraction: widget.expandOnInteraction,
      minimizedTranslation: widget.minimizedTranslation,
      minimizedScale: widget.minimizedScale,
      builder: (context, hasScrolledContent) {
        final effectiveFallback =
            widget.scrollEdgeTreatment && hasScrolledContent
            ? fallbackStyle.copyWith(
                surfaceOpacity: (fallbackStyle.surfaceOpacity + 0.025)
                    .clamp(0, 1)
                    .toDouble(),
                shadowStrength: (fallbackStyle.shadowStrength + 0.08)
                    .clamp(0, 1)
                    .toDouble(),
              )
            : fallbackStyle;
        final content = SizedBox(
          height: navigationValues.height,
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: navigationValues.horizontalPadding,
            ),
            child: Row(
              children: List<Widget>.generate(
                widget.destinations.length,
                (index) => _destination(index, navigationValues),
              ),
            ),
          ),
        );
        final surface = widget._useNativeOverlay
            ? VitreumNativeGlassOverlay(
                shape: widget.shape,
                style: style,
                quality: quality,
                fallbackStyle: effectiveFallback,
                tint: tint,
                inheritTint: false,
                semanticLabel: 'Primary navigation',
                clipBehavior: widget.clipBehavior,
                child: content,
              )
            : VitreumGlass(
                mode: VitreumMode.simulated,
                shape: widget.shape,
                style: style,
                quality: quality,
                fallbackStyle: effectiveFallback,
                tint: tint,
                inheritTint: false,
                semanticLabel: 'Simulated primary navigation',
                clipBehavior: widget.clipBehavior,
                child: content,
              );

        return Stack(
          fit: StackFit.passthrough,
          children: <Widget>[
            surface,
            if (widget.showDebugBounds)
              const Positioned.fill(
                child: IgnorePointer(
                  child: CustomPaint(painter: _BoundsPainter()),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _destination(int index, VitreumNavigationBarStyle style) {
    final destination = widget.destinations[index];
    final selected = widget.selectedIndex == index;
    final pressed = _pressedIndex == index;
    final foreground = selected ? style.selectedColor : style.unselectedColor;

    return Expanded(
      child: Semantics(
        button: true,
        selected: selected,
        label: destination.label,
        child: GestureDetector(
          key: ValueKey<String>('vitreum-navigation-destination-$index'),
          behavior: HitTestBehavior.opaque,
          onTapDown: (_) => setState(() => _pressedIndex = index),
          onTapCancel: () => setState(() => _pressedIndex = null),
          onTapUp: (_) => setState(() => _pressedIndex = null),
          onTap: () => widget.onDestinationSelected(index),
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minWidth: style.destinationMinWidth,
                minHeight: style.destinationMinHeight,
              ),
              child: AnimatedScale(
                scale: pressed ? 0.975 : (selected ? 1.035 : 1),
                duration: const Duration(milliseconds: 100),
                curve: Curves.easeOutCubic,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    AnimatedContainer(
                      width: style.indicatorSize,
                      height: style.indicatorSize,
                      duration: const Duration(milliseconds: 140),
                      curve: Curves.easeOutCubic,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: pressed
                            ? style.pressedIndicatorColor
                            : selected
                            ? style.indicatorColor
                            : Colors.transparent,
                      ),
                      child: Icon(
                        destination.icon,
                        size: style.iconSize,
                        color: foreground,
                      ),
                    ),
                    SizedBox(width: style.itemSpacing),
                    Flexible(
                      child: Text(
                        destination.label,
                        maxLines: 1,
                        overflow: TextOverflow.fade,
                        softWrap: false,
                        style: TextStyle(
                          color: foreground,
                          fontSize: style.labelFontSize,
                          fontWeight: selected
                              ? FontWeight.w600
                              : FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Floating navigation with one native iOS glass surface when supported.
///
/// The destinations, selection, layout, and semantics remain Flutter-owned;
/// this is not a UIKit `UITabBar`. On supported iOS 26 environments, the
/// background uses Apple's public `UIGlassEffect`. Other environments fall
/// back to Vitreum's simulated renderer.
///
/// Use at most one instance on a route and do not combine it with another
/// [VitreumNativeGlassOverlay] on that route. One native overlay is the only
/// validated platform-view composition topology.
class VitreumNativeGlassNavigationBar extends VitreumGlassNavigationBar {
  const VitreumNativeGlassNavigationBar({
    required super.destinations,
    required super.selectedIndex,
    required super.onDestinationSelected,
    super.style,
    super.quality,
    super.fallbackStyle,
    super.navigationStyle,
    super.shape,
    super.tint,
    super.inheritTint,
    super.scrollController,
    super.minimizeOnScroll,
    super.scrollEdgeTreatment,
    super.expandOnInteraction,
    super.minimizedTranslation,
    super.minimizedScale,
    super.clipBehavior,
    super.showDebugBounds,
    super.key,
  }) : super._native();
}

class _BoundsPainter extends CustomPainter {
  const _BoundsPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFFF3B30)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    const length = 10.0;
    final path = Path()
      ..moveTo(0, length)
      ..lineTo(0, 0)
      ..lineTo(length, 0)
      ..moveTo(size.width - length, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width, length)
      ..moveTo(size.width, size.height - length)
      ..lineTo(size.width, size.height)
      ..lineTo(size.width - length, size.height)
      ..moveTo(length, size.height)
      ..lineTo(0, size.height)
      ..lineTo(0, size.height - length);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_BoundsPainter oldDelegate) => false;
}
