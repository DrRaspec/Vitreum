import 'package:flutter/material.dart';

import '../core/vitreum_config.dart';
import '../core/vitreum_shape.dart';
import '../widgets/vitreum_shape_clip.dart';

/// Readable renderer for accessibility and unsupported platforms.
class SolidGlassRenderer extends StatelessWidget {
  const SolidGlassRenderer({
    required this.child,
    required this.shape,
    required this.fallbackStyle,
    required this.tint,
    required this.clipBehavior,
    super.key,
  });

  final Widget child;
  final VitreumShape shape;
  final VitreumFallbackStyle fallbackStyle;
  final Color? tint;
  final Clip clipBehavior;

  @override
  Widget build(BuildContext context) {
    final base =
        tint ??
        (Theme.of(context).brightness == Brightness.dark
            ? const Color(0xFF25272B)
            : const Color(0xFFF2F4F7));
    return Stack(
      fit: StackFit.passthrough,
      children: <Widget>[
        Positioned.fill(
          child: VitreumShapeClip(
            shape: shape,
            clipBehavior: Clip.antiAlias,
            child: DecoratedBox(
              decoration: BoxDecoration(color: base.withValues(alpha: 0.94)),
            ),
          ),
        ),
        VitreumShapeClip(
          shape: shape,
          clipBehavior: clipBehavior,
          child: child,
        ),
      ],
    );
  }
}
