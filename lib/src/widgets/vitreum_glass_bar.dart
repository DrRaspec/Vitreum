import 'package:flutter/material.dart';

import '../core/vitreum_backend.dart';
import '../core/vitreum_config.dart';
import '../core/vitreum_quality.dart';
import '../core/vitreum_shape.dart';
import '../core/vitreum_style.dart';
import '../core/vitreum_theme.dart';
import 'vitreum_glass.dart';
import 'vitreum_scroll_minimizer.dart';

/// Convenience glass surface for toolbars and floating navigation bars.
class VitreumGlassBar extends StatefulWidget {
  const VitreumGlassBar({
    required this.child,
    this.mode = VitreumMode.automatic,
    this.style,
    this.quality,
    this.shape = const VitreumShape.capsule(),
    this.fallbackStyle,
    this.tint,
    this.inheritTint = true,
    this.padding = const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    this.semanticLabel,
    this.scrollController,
    this.minimizeOnScroll = false,
    this.scrollEdgeTreatment = false,
    this.expandOnInteraction = true,
    this.minimizedTranslation = Offset.zero,
    this.minimizedScale = 0.9,
    this.clipBehavior = Clip.antiAlias,
    super.key,
  });

  /// Bar content.
  final Widget child;

  /// Requested backend-selection mode.
  final VitreumMode mode;

  /// Material style, or null to inherit from [VitreumThemeData].
  final VitreumStyle? style;

  /// Simulation quality, or null to inherit from [VitreumThemeData].
  final VitreumQuality? quality;

  /// Bar surface and clipping geometry.
  final VitreumShape shape;

  /// Fallback configuration, or null to inherit from [VitreumThemeData].
  final VitreumFallbackStyle? fallbackStyle;

  /// Optional tint, with theme fallback.
  final Color? tint;

  /// Whether a null [tint] inherits the theme tint.
  final bool inheritTint;

  /// Empty space around [child].
  final EdgeInsetsGeometry padding;

  /// Optional semantic label for the bar container.
  final String? semanticLabel;

  /// Scroll source used by [minimizeOnScroll] and [scrollEdgeTreatment].
  final ScrollController? scrollController;

  /// Minimizes after sustained screen-wise downward user scrolling and
  /// restores on upward scrolling or direct interaction. Navigation remains
  /// visible. Reversed vertical scrollables are detected automatically.
  final bool minimizeOnScroll;

  /// Strengthens separation once content has moved under the bar.
  final bool scrollEdgeTreatment;

  /// Whether pointer interaction restores a minimized bar before the child
  /// handles the same interaction.
  final bool expandOnInteraction;

  /// Fractional translation applied in the minimized state. Bottom bars
  /// normally use a positive Y value; top bars can use a negative value.
  final Offset minimizedTranslation;

  /// Scale applied in the minimized state. The default keeps the transition
  /// restrained while leaving every control visible and selectable.
  final double minimizedScale;

  /// How the Flutter child is clipped to [shape].
  final Clip clipBehavior;

  @override
  State<VitreumGlassBar> createState() => _VitreumGlassBarState();
}

class _VitreumGlassBarState extends State<VitreumGlassBar> {
  @override
  Widget build(BuildContext context) {
    final theme = VitreumThemeData.of(context);
    final style = widget.style ?? theme.style;
    final quality = widget.quality ?? theme.quality;
    final fallbackStyle = widget.fallbackStyle ?? theme.fallbackStyle;
    return VitreumScrollMinimizer(
      scrollController: widget.scrollController,
      minimizeOnScroll: widget.minimizeOnScroll,
      trackScrollEdge: widget.scrollEdgeTreatment,
      expandOnInteraction: widget.expandOnInteraction,
      minimizedTranslation: widget.minimizedTranslation,
      minimizedScale: widget.minimizedScale,
      builder: (context, hasScrolledContent) {
        final fallback = widget.scrollEdgeTreatment && hasScrolledContent
            ? fallbackStyle.copyWith(
                surfaceOpacity: (fallbackStyle.surfaceOpacity + 0.025)
                    .clamp(0, 1)
                    .toDouble(),
                shadowStrength: (fallbackStyle.shadowStrength + 0.08)
                    .clamp(0, 1)
                    .toDouble(),
              )
            : fallbackStyle;
        return VitreumGlass(
          mode: widget.mode,
          style: style,
          quality: quality,
          shape: widget.shape,
          fallbackStyle: fallback,
          tint: widget.tint ?? (widget.inheritTint ? theme.tint : null),
          inheritTint: false,
          semanticLabel: widget.semanticLabel,
          clipBehavior: widget.clipBehavior,
          child: Padding(padding: widget.padding, child: widget.child),
        );
      },
    );
  }
}
