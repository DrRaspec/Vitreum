import 'package:flutter/widgets.dart';

/// Shape families supported consistently by all backends.
enum VitreumShapeKind { roundedRectangle, capsule, circle }

/// An immutable Vitreum surface shape.
@immutable
class VitreumShape {
  /// Creates a rounded rectangle.
  const VitreumShape.roundedRectangle({this.radius = 24})
    : kind = VitreumShapeKind.roundedRectangle;

  /// Creates a capsule.
  const VitreumShape.capsule() : kind = VitreumShapeKind.capsule, radius = 0;

  /// Creates a circle.
  const VitreumShape.circle() : kind = VitreumShapeKind.circle, radius = 0;

  /// Shape family.
  final VitreumShapeKind kind;

  /// Corner radius for [VitreumShapeKind.roundedRectangle].
  final double radius;

  /// Converts this shape to a platform-channel value.
  Map<String, Object> toMap() => <String, Object>{
    'kind': kind.name,
    'radius': radius.isFinite ? radius.clamp(0, 10000) : 0.0,
  };

  /// Creates a Flutter border radius for the supplied bounds.
  BorderRadius borderRadiusFor(Size size) {
    final effectiveRadius = switch (kind) {
      VitreumShapeKind.roundedRectangle =>
        radius.isFinite ? radius.clamp(0, 10000).toDouble() : 0.0,
      VitreumShapeKind.capsule => size.shortestSide / 2,
      VitreumShapeKind.circle => size.shortestSide / 2,
    };
    return BorderRadius.circular(effectiveRadius);
  }

  /// Returns a copy with a different rounded-rectangle radius.
  VitreumShape copyWith({double? radius}) => switch (kind) {
    VitreumShapeKind.roundedRectangle => VitreumShape.roundedRectangle(
      radius: radius ?? this.radius,
    ),
    VitreumShapeKind.capsule => const VitreumShape.capsule(),
    VitreumShapeKind.circle => const VitreumShape.circle(),
  };

  @override
  bool operator ==(Object other) =>
      other is VitreumShape && other.kind == kind && other.radius == radius;

  @override
  int get hashCode => Object.hash(kind, radius);
}
