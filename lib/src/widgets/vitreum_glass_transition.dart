import 'package:flutter/material.dart';

import '../core/vitreum_transition.dart';

/// Coordinates common glass presentation transitions without changing the
/// semantic or pointer behavior of [child].
class VitreumGlassTransition extends StatelessWidget {
  const VitreumGlassTransition({
    required this.child,
    this.type = VitreumTransitionType.materialize,
    this.visible = true,
    this.matchedGeometryTag,
    this.duration = const Duration(milliseconds: 180),
    super.key,
  }) : assert(
         type != VitreumTransitionType.matchedGeometry ||
             matchedGeometryTag != null,
         'matchedGeometry requires matchedGeometryTag.',
       );

  final Widget child;
  final VitreumTransitionType type;
  final bool visible;
  final Object? matchedGeometryTag;

  /// A Vitreum-selected duration, not an Apple timing constant.
  final Duration duration;

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final effectiveDuration = reduceMotion ? Duration.zero : duration;

    final Widget transitioned = switch (type) {
      VitreumTransitionType.identity => Offstage(
        offstage: !visible,
        child: child,
      ),
      VitreumTransitionType.materialize => AnimatedScale(
        duration: effectiveDuration,
        curve: Curves.easeOutCubic,
        scale: visible || reduceMotion ? 1 : 0.94,
        child: Offstage(
          offstage: !visible,
          child: IgnorePointer(ignoring: !visible, child: child),
        ),
      ),
      VitreumTransitionType.matchedGeometry => Hero(
        tag: matchedGeometryTag!,
        createRectTween: (begin, end) =>
            MaterialRectCenterArcTween(begin: begin, end: end),
        transitionOnUserGestures: true,
        child: Offstage(
          offstage: !visible,
          child: IgnorePointer(ignoring: !visible, child: child),
        ),
      ),
    };

    return transitioned;
  }
}
