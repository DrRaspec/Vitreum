import 'package:flutter/widgets.dart';

/// Shares backdrop input among non-overlapping simulated glass descendants.
class VitreumGlassGroup extends StatelessWidget {
  const VitreumGlassGroup({
    required this.child,
    this.spacing = 12,
    this.enableMerging = true,
    this.transitionDuration = const Duration(milliseconds: 180),
    super.key,
  });

  final Widget child;
  final double spacing;
  final bool enableMerging;
  final Duration transitionDuration;

  static bool maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_VitreumGroupMarker>() != null;

  static double mergeSpacingOf(BuildContext context) {
    final marker = context
        .dependOnInheritedWidgetOfExactType<_VitreumGroupMarker>();
    if (marker == null || !marker.enableMerging) return 0;
    return marker.spacing.clamp(0, 48).toDouble();
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    return BackdropGroup(
      child: _VitreumGroupMarker(
        spacing: spacing,
        enableMerging: enableMerging,
        child: AnimatedSize(
          duration: reduceMotion ? Duration.zero : transitionDuration,
          curve: Curves.easeInOutCubic,
          alignment: Alignment.center,
          child: child,
        ),
      ),
    );
  }
}

class _VitreumGroupMarker extends InheritedWidget {
  const _VitreumGroupMarker({
    required this.spacing,
    required this.enableMerging,
    required super.child,
  });

  final double spacing;
  final bool enableMerging;

  @override
  bool updateShouldNotify(_VitreumGroupMarker oldWidget) =>
      oldWidget.spacing != spacing || oldWidget.enableMerging != enableMerging;
}
