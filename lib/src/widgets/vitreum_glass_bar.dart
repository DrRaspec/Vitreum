import 'package:flutter/material.dart';

import '../core/vitreum_backend.dart';
import '../core/vitreum_config.dart';
import '../core/vitreum_quality.dart';
import '../core/vitreum_shape.dart';
import '../core/vitreum_style.dart';
import 'vitreum_glass.dart';

/// Convenience glass surface for toolbars and floating navigation bars.
class VitreumGlassBar extends StatefulWidget {
  const VitreumGlassBar({
    required this.child,
    this.mode = VitreumMode.automatic,
    this.style = VitreumStyle.regular,
    this.quality = VitreumQuality.adaptive,
    this.shape = const VitreumShape.capsule(),
    this.fallbackStyle = const VitreumFallbackStyle(),
    this.tint,
    this.padding = const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    this.semanticLabel,
    this.scrollController,
    this.minimizeOnScroll = false,
    this.scrollEdgeTreatment = false,
    this.minimizedTranslation = const Offset(0, 0.18),
    super.key,
  });

  final Widget child;
  final VitreumMode mode;
  final VitreumStyle style;
  final VitreumQuality quality;
  final VitreumShape shape;
  final VitreumFallbackStyle fallbackStyle;
  final Color? tint;
  final EdgeInsetsGeometry padding;
  final String? semanticLabel;

  /// Scroll source used by [minimizeOnScroll] and [scrollEdgeTreatment].
  final ScrollController? scrollController;

  /// Minimizes after sustained downward scrolling and restores on upward
  /// scrolling or direct interaction. Navigation remains visible.
  final bool minimizeOnScroll;

  /// Strengthens separation once content has moved under the bar.
  final bool scrollEdgeTreatment;

  /// Fractional translation applied in the minimized state. Bottom bars
  /// normally use a positive Y value; top bars can use a negative value.
  final Offset minimizedTranslation;

  @override
  State<VitreumGlassBar> createState() => _VitreumGlassBarState();
}

class _VitreumGlassBarState extends State<VitreumGlassBar> {
  bool _minimized = false;
  bool _hasScrolledContent = false;
  double _lastOffset = 0;
  double _directionDistance = 0;

  @override
  void initState() {
    super.initState();
    _attach(widget.scrollController);
  }

  @override
  void didUpdateWidget(VitreumGlassBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.scrollController != widget.scrollController) {
      _detach(oldWidget.scrollController);
      _attach(widget.scrollController);
    }
  }

  void _attach(ScrollController? controller) {
    controller?.addListener(_handleScroll);
    if (controller?.hasClients ?? false) _lastOffset = controller!.offset;
  }

  void _detach(ScrollController? controller) {
    controller?.removeListener(_handleScroll);
  }

  void _handleScroll() {
    final controller = widget.scrollController;
    if (controller == null || !controller.hasClients) return;
    final offset = controller.offset;
    final delta = offset - _lastOffset;
    _lastOffset = offset;
    final hasContent = offset > 2;

    if (delta.sign != _directionDistance.sign) _directionDistance = 0;
    _directionDistance += delta;

    var minimized = _minimized;
    if (widget.minimizeOnScroll && offset > 24 && _directionDistance > 18) {
      minimized = true;
      _directionDistance = 0;
    } else if (_directionDistance < -12 || offset <= 2) {
      minimized = false;
      _directionDistance = 0;
    }

    if (minimized != _minimized || hasContent != _hasScrolledContent) {
      setState(() {
        _minimized = minimized;
        _hasScrolledContent = hasContent;
      });
    }
  }

  void _restoreForInteraction() {
    if (_minimized) setState(() => _minimized = false);
  }

  @override
  void dispose() {
    _detach(widget.scrollController);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final duration = reduceMotion
        ? Duration.zero
        : const Duration(milliseconds: 180);
    final fallback = widget.scrollEdgeTreatment && _hasScrolledContent
        ? widget.fallbackStyle.copyWith(
            surfaceOpacity: (widget.fallbackStyle.surfaceOpacity + 0.025)
                .clamp(0, 1)
                .toDouble(),
            shadowStrength: (widget.fallbackStyle.shadowStrength + 0.08)
                .clamp(0, 1)
                .toDouble(),
          )
        : widget.fallbackStyle;

    return Listener(
      onPointerDown: (_) => _restoreForInteraction(),
      child: AnimatedSlide(
        duration: duration,
        curve: Curves.easeInOutCubic,
        offset: _minimized ? widget.minimizedTranslation : Offset.zero,
        child: AnimatedScale(
          duration: duration,
          curve: Curves.easeInOutCubic,
          scale: _minimized ? 0.86 : 1,
          child: VitreumGlass(
            mode: widget.mode,
            style: widget.style,
            quality: widget.quality,
            shape: widget.shape,
            fallbackStyle: fallback,
            tint: widget.tint,
            semanticLabel: widget.semanticLabel,
            child: Padding(padding: widget.padding, child: widget.child),
          ),
        ),
      ),
    );
  }
}
