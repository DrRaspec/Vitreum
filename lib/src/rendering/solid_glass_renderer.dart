import 'package:flutter/material.dart';

import '../core/vitreum_config.dart';
import '../core/vitreum_shape.dart';

/// Readable renderer for accessibility and unsupported platforms.
class SolidGlassRenderer extends StatelessWidget {
  const SolidGlassRenderer({
    required this.child,
    required this.shape,
    required this.fallbackStyle,
    required this.tint,
    super.key,
  });

  final Widget child;
  final VitreumShape shape;
  final VitreumFallbackStyle fallbackStyle;
  final Color? tint;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final size = Size(
        constraints.hasBoundedWidth ? constraints.maxWidth : 0,
        constraints.hasBoundedHeight ? constraints.maxHeight : 0,
      );
      final base =
          tint ??
          (Theme.of(context).brightness == Brightness.dark
              ? const Color(0xFF25272B)
              : const Color(0xFFF2F4F7));
      return ClipRRect(
        borderRadius: shape.borderRadiusFor(size),
        child: DecoratedBox(
          decoration: BoxDecoration(color: base.withValues(alpha: 0.94)),
          child: child,
        ),
      );
    },
  );
}
