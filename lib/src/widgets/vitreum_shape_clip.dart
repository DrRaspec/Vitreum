import 'package:flutter/widgets.dart';

import '../core/vitreum_shape.dart';

Path vitreumShapePath(Size size, VitreumShape shape, {double inset = 0}) {
  final safeInset = inset.isFinite
      ? inset.clamp(0, size.shortestSide / 2).toDouble()
      : 0.0;
  final rect = (Offset.zero & size).deflate(safeInset);
  return switch (shape.kind) {
    VitreumShapeKind.roundedRectangle =>
      Path()..addRRect(
        RRect.fromRectAndRadius(
          rect,
          Radius.circular(
            (shape.radius - safeInset).clamp(0, rect.shortestSide / 2),
          ),
        ),
      ),
    VitreumShapeKind.capsule =>
      Path()..addRRect(
        RRect.fromRectAndRadius(rect, Radius.circular(rect.shortestSide / 2)),
      ),
    VitreumShapeKind.circle =>
      Path()..addOval(
        Rect.fromCircle(center: rect.center, radius: rect.shortestSide / 2),
      ),
  };
}

class VitreumShapeClip extends StatelessWidget {
  const VitreumShapeClip({
    required this.shape,
    required this.clipBehavior,
    required this.child,
    super.key,
  });

  final VitreumShape shape;
  final Clip clipBehavior;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (clipBehavior == Clip.none) return child;
    return ClipPath(
      clipper: _VitreumShapeClipper(shape),
      clipBehavior: clipBehavior,
      child: child,
    );
  }
}

class _VitreumShapeClipper extends CustomClipper<Path> {
  const _VitreumShapeClipper(this.shape);

  final VitreumShape shape;

  @override
  Path getClip(Size size) => vitreumShapePath(size, shape);

  @override
  bool shouldReclip(_VitreumShapeClipper oldClipper) =>
      oldClipper.shape != shape;
}
